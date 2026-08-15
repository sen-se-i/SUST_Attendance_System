# Project Directory Structure & File Index

This document maps the entire directory structure of the **SUST Attendance System** from the root folder down to every single codebase file, along with a quick one-sentence explanation of what each file does.

---

## 📁 1. Root Directory Configurations

These files set up containerization, environment variables, build pipelines, and deployment settings for the overall project.

* [`.dockerignore`](file:///c:/Users/Qbits/Documents/attendanceSystem/.dockerignore) - Tells Docker which files (like `node_modules` or `.git`) to exclude from the container image build.
* [`.gitignore`](file:///c:/Users/Qbits/Documents/attendanceSystem/.gitignore) - Specifies which files Git should ignore (e.g., compile targets, local secrets, ide settings).
* [`Dockerfile`](file:///c:/Users/Qbits/Documents/attendanceSystem/Dockerfile) - Multi-stage script that packages the Spring Boot backend using Maven 3.9 and Temurin JRE 21.
* [`docker-compose.yml`](file:///c:/Users/Qbits/Documents/attendanceSystem/docker-compose.yml) - Configuration file to launch a local PostgreSQL 16 container bound to port 5432 with persistent volume mounts.
* [`pom.xml`](file:///c:/Users/Qbits/Documents/attendanceSystem/pom.xml) - Maven configuration file defining dependencies, plugins, and Java versions for the backend.
* [`render.yaml`](file:///c:/Users/Qbits/Documents/attendanceSystem/render.yaml) - Infrastructure-as-code configuration to spin up a web service and a Postgres database on Render.com automatically.
* [`mvnw`](file:///c:/Users/Qbits/Documents/attendanceSystem/mvnw) & [`mvnw.cmd`](file:///c:/Users/Qbits/Documents/attendanceSystem/mvnw.cmd) - Unix and Windows scripts to execute Maven commands without having Maven pre-installed on the host system.
* [`README.md`](file:///c:/Users/Qbits/Documents/attendanceSystem/README.md) - General description of the project, features, and setup instructions.

---

## 📁 2. Docs Folder (`docs/`)

Contains design diagrams and complete guides for frontend, backend, and integration details.

* `docs/diagrams/`
  * [`dfd_data_flow_diagram.png`](file:///c:/Users/Qbits/Documents/attendanceSystem/docs/diagrams/dfd_data_flow_diagram.png) - Visual model of how data flows between users, controllers, and the database.
  * [`erd_database_schema.png`](file:///c:/Users/Qbits/Documents/attendanceSystem/docs/diagrams/erd_database_schema.png) - Database entity-relationship diagram displaying tables, columns, and foreign keys.
  * [`uml_sequence_diagram.png`](file:///c:/Users/Qbits/Documents/attendanceSystem/docs/diagrams/uml_sequence_diagram.png) - Sequential flow mapping user actions (start, scan, claim, verify) over time.
* [`frontend_guide.md`](file:///c:/Users/Qbits/Documents/attendanceSystem/docs/frontend_guide.md) - Comprehensive developer guide for the React web app and Flutter mobile app.
* [`backend_guide.md`](file:///c:/Users/Qbits/Documents/attendanceSystem/docs/backend_guide.md) - Deep dive guide explaining Spring Boot services, controllers, database mappings, and cryptos.
* [`system_integration_guide.md`](file:///c:/Users/Qbits/Documents/attendanceSystem/docs/system_integration_guide.md) - Integration manual explaining websockets, deployment, and Haversine geofence formulas.

---

## 📁 3. Web Frontend (`frontend/`)

The React Single Page Application (SPA) compiled with Vite and packaged for native platforms via Capacitor.

* **Root Configuration Files**:
  * [`.env`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/.env) - Local development environment properties.
  * [`.oxlintrc.json`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/.oxlintrc.json) - Configuration rules for the ultra-fast Oxlint code linter.
  * [`capacitor.config.json`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/capacitor.config.json) - Bridge configuration that wraps the Vite build bundle inside a native Android shell.
  * [`index.html`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/index.html) - Entry HTML page where React mounts its root element.
  * [`package.json`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/package.json) - Holds dependency lists, build commands, and script metadata.
  * [`vite.config.js`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/vite.config.js) - Bundler configurations defining React plugins and local server options.
  * [`scripts/copy-to-static.mjs`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/scripts/copy-to-static.mjs) - Script that automatically copies Vite production build assets from `frontend/dist/` into Spring Boot’s resources directory (`static/`).

* **Source Files (`frontend/src/`)**:
  * [`main.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/main.jsx) - Entry Javascript source mounting the main React App component.
  * [`App.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/App.jsx) - Combines global provider contexts (Auth/Toast) and sets up the router endpoints.
  * [`index.css`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/index.css) - Main stylesheet defining the layout grid, utility tokens, and Glassmorphism theme.
  * [`App.css`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/App.css) - Supplementary stylesheet containing component specific overrides.
  * **Reusable Components (`components/`)**:
    * [`Layout.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/components/Layout.jsx) - Defines the site navbar, sidebar drawer, header layout, and active user panels.
    * [`ProtectedRoute.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/components/ProtectedRoute.jsx) - Secures paths so unauthenticated users or users with invalid roles are redirected.
    * [`AttendanceTable.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/components/AttendanceTable.jsx) - Formats scan logs, distance, and timestamps into tables.
    * [`ScannerPanel.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/components/ScannerPanel.jsx) - Camera capture component using `html5-qrcode` to read dynamic payloads.
    * [`SessionPanel.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/components/SessionPanel.jsx) - Controls for teachers to select radii, calibrate their own GPS, and launch or stop sessions.
  * **Helper Logic (`lib/`)**:
    * [`config.js`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/lib/config.js) - Sets backend host URLs (falling back to Render.com URL) and determines WebSocket protocol schemes (WS vs WSS).
    * [`api.js`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/lib/api.js) - Core HTTP client wrapper appending JWT tokens, handling server timeout aborts, and fetching raw image blobs.
    * [`deviceId.js`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/lib/deviceId.js) - Generates and caches a persistent browser install UUID to flag multi-account attendance cheats.
    * [`location.js`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/lib/location.js) - High-accuracy GPS location capture module implementing a 6-step calibration loop.
    * [`AuthContext.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/lib/AuthContext.jsx) - State management context exposing login, register, and logout handlers.
    * [`ToastContext.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/lib/ToastContext.jsx) - UI state context emitting interactive status alert toasts to users.
  * **Pages (`pages/`)**:
    * [`AuthPage.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/pages/AuthPage.jsx) - Holds login and role-based registration forms.
    * [`TeacherDashboard.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/pages/TeacherDashboard.jsx) - Dashboard for teachers to add classes, save rosters, and track live session records.
    * [`StudentDashboard.jsx`](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/pages/StudentDashboard.jsx) - Dashboard for students to join courses, verify coordinates, and review personal logs.

---

## 📁 4. Flutter Mobile App (`flutter_app/`)

Cross-platform native mobile client compiled with Flutter.

* [`pubspec.yaml`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/pubspec.yaml) - Flutter package manager file defining assets, plugins (like `geolocator`), and build SDKs.
* **Source Files (`lib/`)**:
  * [`main.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/main.dart) - Launches the Flutter app, sets up routing paths, and defines basic UI styling themes.
  * **Data Models (`models/`)**:
    * [`user_model.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/models/user_model.dart) - Model class for user profiles, credentials, and token parsing.
    * [`class_model.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/models/class_model.dart) - Model class mapping course data details.
    * [`session_model.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/models/session_model.dart) - Model class holding active/expired attendance session values.
    * [`attendance_model.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/models/attendance_model.dart) - Model class formatting verify responses and scan logs.
  * **State Providers (`providers/`)**:
    * [`auth_provider.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/providers/auth_provider.dart) - Handles user states, logins, logouts, and token caching in Flutter memory.
  * **Screens (`screens/`)**:
    * [`login_screen.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/screens/login_screen.dart) - Native layout for logging in or signing up students and teachers.
    * [`teacher_dashboard_screen.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/screens/teacher_dashboard_screen.dart) - Screen rendering teacher controls, rosters, class creation, and session startups.
    * [`student_dashboard_screen.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/screens/student_dashboard_screen.dart) - Screen displaying student joined classes and geofence marking buttons.
  * **Services (`services/`)**:
    * [`api_service.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/services/api_service.dart) - HTTP network helper wrapping API calls using Dart's native network clients.
    * [`location_service.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/services/location_service.dart) - Geolocation service using the native GPS geolocator to verify coordinate signals via a 6-attempt loop.
  * **Widgets (`widgets/`)**:
    * [`location_radar_widget.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/widgets/location_radar_widget.dart) - Custom widget displaying a radar animation during location capture.
    * [`radius_slider_widget.dart`](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/widgets/radius_slider_widget.dart) - Custom slider widget for setting the geofence radius.

---

## 📁 5. Java Backend Service (`src/`)

### A. Source Directory (`src/main/`)

* **Java Configurations & Logic (`java/com/jarvisatt/attendance/`)**:
  * [`AttendanceApplication.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/AttendanceApplication.java) - Root class containing the main method that runs the Spring Boot application.
  * **Config Configuration Beans (`config/`)**:
    * [`CryptoProperties.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/config/CryptoProperties.java) - Maps AES keys and HMAC secrets from configuration files.
    * [`JwtProperties.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/config/JwtProperties.java) - Maps JWT secrets and Token Time-to-Live settings.
    * [`SchedulerConfig.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/config/SchedulerConfig.java) - Configures task schedulers supporting dynamic async QR ticking tasks.
    * [`SecurityConfig.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/config/SecurityConfig.java) - Configures stateless JWT authentication filters, CORS scopes, and endpoint rules.
    * [`WebSocketConfig.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/config/WebSocketConfig.java) - Configures real-time STOMP brokers mapping client endpoints to `/ws`.
    * [`DataInitializer.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/config/DataInitializer.java) - Populates test accounts and initial data sets in dev database mode.
  * **REST Endpoints Routing (`controller/`)**:
    * [`AuthController.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/controller/AuthController.java) - Routes login and registration calls.
    * [`ClassController.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/controller/ClassController.java) - Routes creating, searching, joining, and listing classes.
    * [`RosterController.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/controller/RosterController.java) - Routes uploads and updates to roster class lists.
    * [`SessionController.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/controller/SessionController.java) - Routes starting/stopping sessions, checking active flags, and rendering `/qr.png` blobs.
    * [`AttendanceController.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/controller/AttendanceController.java) - Routes claiming, checking, and retrieving attendance logs.
    * [`EnrollmentController.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/controller/EnrollmentController.java) - Routes queries regarding active class enrollments.
  * **Cryptography Services (`crypto/`)**:
    * [`TickPayload.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/crypto/TickPayload.java) - Record defining fields stored in dynamic QR tokens (Session UUID, index, and nonce).
    * [`AesPayloadCipher.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/crypto/AesPayloadCipher.java) - Encrypts/decrypts tick payloads using the authenticated AES/GCM algorithm.
    * [`HmacTokenService.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/crypto/HmacTokenService.java) - Computes secure random nonces, signs payloads via HMAC-SHA256, and generates database lookup hashes.
  * **Database Entity Mappings (`domain/`)**:
    * [`Role.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/domain/Role.java) - Enumerated user roles: `STUDENT` or `ADMIN` (Teacher).
    * [`User.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/domain/User.java) - Maps table `users` containing credentials, registration number, and creation timestamps.
    * [`ClassEntity.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/domain/ClassEntity.java) - Maps table `classes` containing subject codes, generated codes, and references to the teacher User.
    * [`ClassRosterEntry.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/domain/ClassRosterEntry.java) - Maps table `class_roster` defining the allowlist of registration numbers for specific classes.
    * [`EnrollmentStatus.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/domain/EnrollmentStatus.java) - Enumerated enrollment states: `PENDING` or `ACTIVE`.
    * [`Enrollment.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/domain/Enrollment.java) - Maps table `enrollments` linking students to joined classes.
    * [`ClassSessionStatus.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/domain/ClassSessionStatus.java) - Enumerated class session states: `ACTIVE` or `ENDED`.
    * [`ClassSession.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/domain/ClassSession.java) - Maps table `class_sessions` holding teacher coords, accuracy levels, target radius, and status limits.
    * [`QrTick.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/domain/QrTick.java) - Maps table `qr_ticks` storing HMAC signatures, rotation indices, and expiration timers.
    * [`AttendanceRecord.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/domain/AttendanceRecord.java) - Maps table `attendance_records` logging student claims, GPS accuracy levels, device hardware profiles, and distances.
    * [`Device.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/domain/Device.java) - Maps table `devices` mapping specific hardware tokens to student profiles.
  * **Payload Data Transfer Objects (`dto/`)**:
    * [`AuthDtos.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/dto/AuthDtos.java) - Records modeling auth logins, registrations, and token responses.
    * [`ClassDtos.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/dto/ClassDtos.java) - Records modeling class creations, roster uploads, and joins.
    * [`SessionDtos.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/dto/SessionDtos.java) - Records modeling session starts, active updates, and tick broadcasts.
    * [`AttendanceDtos.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/dto/AttendanceDtos.java) - Records modeling verify and claim requests and responses.
  * **Exceptions (`exception/`)**:
    * [`ApiException.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/exception/ApiException.java) - Global API exception returning structured JSON error details and customized HTTP status codes to users.
  * **Database JPA Access (`repository/`)**:
    * [`UserRepository.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/repository/UserRepository.java) - Query interfaces for user profile search.
    * [`ClassRepository.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/repository/ClassRepository.java) - Query interfaces for classes and search filters.
    * [`ClassRosterRepository.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/repository/ClassRosterRepository.java) - Query interfaces verifying registration numbers in roster lists.
    * [`EnrollmentRepository.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/repository/EnrollmentRepository.java) - Query interfaces mapping enrollment logs.
    * [`ClassSessionRepository.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/repository/ClassSessionRepository.java) - Query interfaces searching active geofence sessions.
    * [`QrTickRepository.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/repository/QrTickRepository.java) - Query interfaces tracking HMAC tick rotations.
    * [`AttendanceRecordRepository.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/repository/AttendanceRecordRepository.java) - Query interfaces fetching student logs and class-level logs.
    * [`DeviceRepository.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/repository/DeviceRepository.java) - Query interfaces locating saved device install IDs.
  * **Authentication Security Filters (`security/`)**:
    * [`AppUserDetailsService.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/security/AppUserDetailsService.java) - Integrates with Spring Security to retrieve user records from the database using emails.
    * [`UserPrincipal.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/security/UserPrincipal.java) - Principal record containing the authenticated user's ID, email, registration number, and security roles.
    * [`JwtService.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/security/JwtService.java) - Code helper generating, parsing, and verifying JWT authorization tokens.
    * [`JwtAuthenticationFilter.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/security/JwtAuthenticationFilter.java) - Filter intercepting incoming requests, extracting JWT authorization headers, and validating identities.
  * **Business Services (`service/`)**:
    * [`AuthService.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/service/AuthService.java) - Coordinates logins and registration validation rules.
    * [`ClassService.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/service/ClassService.java) - Creates classes, generates 6-character unique class codes, and validates ownership.
    * [`RosterService.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/service/RosterService.java) - Saves allowlisted student roster lists to the database.
    * [`EnrollmentService.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/service/EnrollmentService.java) - Connects student profiles to class enrollment maps.
    * [`QrCodeService.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/service/QrCodeService.java) - Generates QR code images as raw `.png` bytes using a local ZXing writer.
    * [`SessionLifecycleService.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/service/SessionLifecycleService.java) - Core lifecycle service launching, stopping, validating, and fetching geofence sessions.
    * [`AttendanceService.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/service/AttendanceService.java) - Core service checking geofences, calculating distances, mapping device limits, and saving attendance records.
    * [`notification/NotificationService.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/service/notification/NotificationService.java) - Standard service notifying users of successful attendance scans.
  * **Active Session Schedulers (`session/`)**:
    * [`CurrentTick.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/session/CurrentTick.java) - Record storing current tick indices, hashes, payloads, and expiration times.
    * [`TickBroadcastMessage.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/session/TickBroadcastMessage.java) - Record representing the broadcast model sent to WebSocket clients.
    * [`SessionRuntimeState.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/session/SessionRuntimeState.java) - Tracks running session properties and active ticks in memory.
    * [`SessionEngine.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/session/SessionEngine.java) - Scheduler engine rotating HMAC tokens, updating database logs, and broadcasting changes over WebSockets.
    * [`OrphanedSessionCleanup.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/java/com/jarvisatt/attendance/session/OrphanedSessionCleanup.java) - Cleanup module locating and stopping expired sessions left open due to server crashes.

* **Database Schema Migrations & Properties (`resources/`)**:
  * [`application.yml`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/resources/application.yml) - Configuration file setting datasource URLs, flyway flags, mail servers, and JWT/Crypto keys.
  * `db/migration/`
    * [`V1__init_schema.sql`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/resources/db/migration/V1__init_schema.sql) - Initial schema mapping database tables (users, classes, enrollments, sessions, ticks, devices, records).
    * [`V2__gps_attendance.sql`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/resources/db/migration/V2__gps_attendance.sql) - Schema migration appending geofencing support columns (latitude, longitude, radius, and distance).
    * [`V3__gps_accuracy_calibration.sql`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/main/resources/db/migration/V3__gps_accuracy_calibration.sql) - Schema migration adding accuracy constraints to audit strict coordinate readings.

---

## 📁 6. Java Backend Tests (`src/test/`)

* [`AttendanceFlowIntegrationTest.java`](file:///c:/Users/Qbits/Documents/attendanceSystem/src/test/java/com/jarvisatt/attendance/AttendanceFlowIntegrationTest.java) - Integration tests verifying geofence distance failures, replay attacks, concurrent race locks on tokens, and accuracy calibration constraints using Testcontainers and Awaitility.
