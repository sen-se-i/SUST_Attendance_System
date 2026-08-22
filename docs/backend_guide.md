# Backend Developer & Architecture Guide

Welcome to the backend architecture guide of the **SUST Attendance System**. This document breaks down the Java Spring Boot backend, explaining the technology stack, directory structure, core modules, database models, and critical service logic.

---

## 🚀 1. The Technology Stack

The backend is built as a robust, enterprise-grade service using:
* **Java 21**: Features modern constructs like Records, pattern matching, and Virtual Threads.
* **Spring Boot 3**: The framework used to manage dependencies, boot up the embedded Tomcat web server, and autoconfigure beans.
* **Spring Security & JWT**: Secures endpoints. It uses stateless JSON Web Token (JWT) authorization, custom filters, and BCrypt to hash passwords.
* **Spring Data JPA & Hibernate**: Object-Relational Mapping (ORM) framework that lets us write Java entities and translates them into SQL queries.
* **Flyway**: Database schema migration tool. It runs versioned SQL scripts (located in `resources/db/migration/`) on application boot to update the schema.
* **Spring WebSockets & STOMP**: A lightweight publish-subscribe sub-protocol used to stream live updates (such as changing QR ticks) to connected clients.
* **Lombok**: Annotation library that auto-generates constructor, getter, setter, and builder code, keeping the Java files clean.
* **PostgreSQL**: The relational database management system (RDBMS) used for data persistence.

---

## 📁 2. Backend Package Directory (`src/main/java/com/jarvisatt/attendance/`)

The Java codebase follows standard Spring Boot package-by-layer conventions:

```
com/jarvisatt/attendance/
├── AttendanceApplication.java      # Application main runner
├── config/                         # Configuration beans (Security, WS, Schedulers)
│   ├── SecurityConfig.java
│   └── WebSocketConfig.java
├── controller/                     # REST API routing controllers
│   ├── AttendanceController.java
│   ├── AuthController.java
│   ├── ClassController.java
│   └── SessionController.java
├── crypto/                         # Security algorithms (AES-GCM, HMAC, JWT helper)
│   ├── AesPayloadCipher.java
│   └── HmacTokenService.java
├── domain/                         # JPA database entity models
│   ├── AttendanceRecord.java
│   ├── ClassEntity.java
│   ├── ClassSession.java
│   ├── Device.java
│   ├── QrTick.java
│   └── User.java
├── dto/                            # Data Transfer Objects (Payload Records)
│   └── AttendanceDtos.java
├── repository/                     # Database JPA access layers
│   ├── AttendanceRecordRepository.java
│   └── UserRepository.java
├── security/                       # Custom security filters and details
│   ├── JwtAuthenticationFilter.java
│   └── JwtService.java
├── service/                        # Business logic execution services
│   ├── AttendanceService.java
│   └── SessionLifecycleService.java
└── session/                        # Real-time ticking system runtime engine
    ├── SessionEngine.java
    └── SessionRuntimeState.java
```

---

## 🔧 3. Core Architecture & Classes Explained

### 🔑 1. Security & Authentication Config
* **Where to find**: [SecurityConfig.java](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/config/SecurityConfig.java) and [JwtAuthenticationFilter.java](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/security/JwtAuthenticationFilter.java)
* **What it does**: Controls access permissions, checks logins, and intercepts routes.
* **How it works**:
  * `SecurityConfig` disables Cross-Site Request Forgery (`CSRF`) check because the app uses stateless JWT tokens (passed in headers, not cookies) which are immune to CSRF.
  * Explicitly allows anyone to access index HTML paths, register/login endpoints `/api/auth/**`, and the WebSocket endpoint `/ws/**`. All other routes require authentication.
  * Adds `JwtAuthenticationFilter` before standard authentication. This filter extracts the `Authorization: Bearer <token>` header, decodes it using `JwtService` to find the user ID and role, and maps it to a `UsernamePasswordAuthenticationToken` in Spring's Security context.

### 🛡️ 2. QR Code Cryptography
* **Where to find**: [AesPayloadCipher.java](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/crypto/AesPayloadCipher.java) and [HmacTokenService.java](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/crypto/HmacTokenService.java)
* **What it does**: Ensures that dynamic QR code payloads are secure, tamper-proof, and cannot be screenshotted and shared (replayed).
* **How it works**:
  * **AES Encryption**: `AesPayloadCipher` uses **AES/GCM/NoPadding** (128-bit security tag, 12-byte random initialization vector). It encrypts the `(sessionId, tickIndex, nonce)` tuple and prints it as a URL-safe Base64 string. GCM mode is used because it is authenticated—if anyone tries to modify the QR payload, decryption will fail immediately.
  * **HMAC Signatures**: `HmacTokenService` generates a one-time random token using **HmacSHA256** keyed by a backend secret (`JARVIS_HMAC_SECRET`).
  * When a new tick is created, the system stores the **SHA-256 hash** of this token in the database.
  * When a student scans the QR code, the client sends the encrypted payload back. The backend decrypts it, regenerates the token and its hash using its HMAC secret, and compares it to the database record. Since the student doesn't know the HMAC secret, they cannot pre-generate or forge tickets!

### ⏳ 3. Dynamic Session Rotation Engine
* **Where to find**: [SessionEngine.java](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/session/SessionEngine.java)
* **What it does**: Manages the rotation (ticking) of QR codes for active sessions in real-time.
* **How it works**:
  * Uses a thread-safe `ConcurrentHashMap` (`states`) to track running sessions in memory.
  * When a teacher starts a session, `SessionEngine` uses Spring's `ThreadPoolTaskScheduler` to schedule a recurring task (`rotate(...)`) at a fixed rate (typically every 1 second, up to a total of 150 seconds).
  * In each tick rotation:
    1. It fetches the session details.
    2. Updates the previous tick status in the database to expired.
    3. Generates a fresh random `nonce` and a new `HmacSHA256` token, saving its SHA-256 hash in `qr_ticks`.
    4. Encrypts the current `(sessionId, tickIndex, nonce)` using AES-GCM.
    5. Sends this new QR payload to the frontend over WebSockets using Spring's `SimpMessagingTemplate` on the path `/topic/sessions/{sessionId}/ticks`.
  * If the session hits the maximum duration limit (150 ticks), it cancels the scheduler task and marks the session as `ENDED`.

### 📍 4. Attendance Verification & Geofencing
* **Where to find**: [AttendanceService.java](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/service/AttendanceService.java)
* **What it does**: Validates and marks attendance for students based on location, distance, and device.
* **How it works**:
  * **Roster Check**: Ensures the student's registration number is in the teacher-defined class allowlist (`class_roster`).
  * **Enrollment Check**: Ensures the student has joined the class.
  * **Duplicate Prevention**: Rejects requests if attendance is already marked.
  * **GPS Freshness**: The timestamp of the student's GPS coordinate capture is verified to ensure it was captured within the last **15 seconds** (preventing students from using old coordinate spoof data).
  * **Haversine Distance**: Computes the distance in meters between the student's coordinates and the teacher's coordinates.
  * **Geofence Check**: Ensures the distance is smaller than the classroom radius (e.g., 20m).
  * **Calibrated Confidence**: Runs a mathematical check: `distanceMeters + accuracyMeters <= radiusMeters`. If the student's distance plus their GPS margin of error exceeds the geofence radius, it is rejected.
  * **Device ID Verification & Locking**: Registers the `deviceInstallId` mapping to the student's account on login, registration, and attendance claims. If a different student attempts to log in, register, or mark attendance from a device already linked to another student, the request is rejected with a `CONFLICT` status. This prevents proxy attendance by ensuring a device cannot be shared between multiple student accounts.
