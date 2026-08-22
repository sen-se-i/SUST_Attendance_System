# Frontend Developer & Architecture Guide

Welcome to the frontend documentation of the **SUST Attendance System**. This guide is designed to teach a beginner exactly what tech stack is used, where code is located, how components and services work, and why they are implemented the way they are.

---

## 🚀 1. The Technology Stack

The frontend is implemented using two parallel technologies:
1. **React Web Application** (located in `frontend/`) - A modern Single Page Application (SPA) designed to run in desktop/mobile web browsers and packaged via **Capacitor** to run as a native Android container.
2. **Flutter Mobile Application** (located in `flutter_app/`) - A native mobile application built using Google's Flutter framework, written in Dart, providing a smooth native user experience.

### React Web Stack Details
* **Vite**: The build tool and bundler. It is faster than legacy tools like Webpack because it uses native ES modules during development and optimized Rollup builds for production.
* **React 19 & React DOM**: The core library for building declarative, component-based user interfaces.
* **React Router DOM (v7)**: Handles routing (page transitions, protecting access based on login status) without reloading the page.
* **Stomp & WebSockets (`@stomp/stompjs`)**: Used to maintain a persistent connection with the server so the teacher dashboard and student devices receive real-time signals (e.g., active GPS session, rotating QR codes).
* **HTML5 QR Code Scanner (`html5-qrcode`)**: A library that hooks into the browser camera to capture, scan, and parse QR code payloads.
* **Lucide React**: Premium icon set that keeps the interface looking professional and clean.
* **Capacitor**: A cross-platform runtime that wraps our Vite web build into a native Android shell. It allows browser code to interact with native mobile features and package as an `.apk` file.

### Flutter Stack Details
* **Dart**: The programming language used by Flutter, combining modern features like sound null safety, async/await, and rapid hot-reload development.
* **Geolocator**: A Flutter package that communicates directly with Android/iOS native Location Services (GPS, Wi-Fi triangulation, and cell towers) to get high-accuracy coordinates.
* **Http**: Dart client library used to communicate with the REST API backend.

---

## 📁 2. React Frontend Structure (`frontend/src/`)

The React application is modularly split into components, pages, utility libraries, and configuration files.

```
frontend/src/
├── App.css               # Page-specific styling overrides
├── App.jsx               # Application root, defines router and contexts
├── index.css             # Main styling system, theme tokens, glassmorphism UI
├── main.jsx              # Application entry point mounting React
├── assets/               # Static images and icons
├── components/           # Reusable UI elements
│   ├── AttendanceTable.jsx
│   ├── Layout.jsx
│   ├── ProtectedRoute.jsx
│   ├── ScannerPanel.jsx
│   └── SessionPanel.jsx
├── lib/                  # State, API integrations, and helper logic
│   ├── AuthContext.jsx
│   ├── ToastContext.jsx
│   ├── api.js
│   ├── config.js
│   ├── deviceId.js
│   └── location.js
└── pages/                # Page views mapped to Router paths
    ├── AuthPage.jsx
    ├── StudentDashboard.jsx
    └── TeacherDashboard.jsx
```

### Key Libraries & Components (`frontend/src/lib/`)

#### 📍 1. GPS Location Services (`lib/location.js`)
* **Where to find**: [location.js](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/lib/location.js)
* **What it does**: Accesses the device's GPS and runs an accuracy calibration loop.
* **How it works**:
  * Calls the browser's native `navigator.geolocation.getCurrentPosition(...)` with `{ enableHighAccuracy: true }` to force hardware GPS usage instead of weak network IP guesses.
  * It has a target accuracy check (like 20 meters, or a minimum of 3 meters).
  * Runs a **calibration loop (up to 6 times)**, waiting 700 milliseconds between attempts. In each attempt, it compares the accuracy value (lower is more accurate).
  * If it achieves the desired accuracy, it stops early and returns the coordinates. If it fails to reach target accuracy after 6 attempts, it warns the user that the GPS signal is too weak.
* **Why it's used**: GPS readings can initially be highly inaccurate (e.g., hundreds of meters off) while the GPS receiver connects to satellites. Calibration ensures the system only records high-confidence coordinates for geofence verification.

#### 🔌 2. API Communication Hub (`lib/api.js`)
* **Where to find**: [api.js](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/lib/api.js)
* **What it does**: Handles HTTP requests to the backend server.
* **How it works**:
  * Defines a custom `api(path, options)` function wrapping the native `fetch` API.
  * Automatically retrieves the authorization token from local storage and appends the `Authorization: Bearer <token>` header to authenticate the user.
  * Uses an `AbortController` to timeout requests after **90 seconds** (giving the backend on Render.com time to wake up if it went to sleep on the free tier).
  * Gracefully handles server response errors by extracting JSON error message fields.
* **Why it's used**: Centering all API requests in one wrapper eliminates code duplication and ensures uniform error feedback across the app.

#### 🔒 3. Device Identification (`lib/deviceId.js`)
* **Where to find**: [deviceId.js](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/lib/deviceId.js)
* **What it does**: Retrieves or creates a unique identifier for the user's device.
* **How it works**:
  * Looks up a key (`jarvisatt.deviceInstallId`) in the browser's persistent `localStorage`.
  * If it doesn't exist, it generates a cryptographically secure UUID (`crypto.randomUUID()`) or falls back to a timestamp + random hex string, and stores it.
* **Why it's used**: Used by the backend to prevent proxy/remote attendance cheating. A student cannot log into multiple accounts on the same browser/app instance and mark attendance for classmates because the same `deviceInstallId` will flag a conflict.

#### 🔑 4. Authentication Context (`lib/AuthContext.jsx`)
* **Where to find**: [AuthContext.jsx](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/lib/AuthContext.jsx)
* **What it does**: Manages log-in, registration, log-out states, and user sessions.
* **How it works**:
  * Uses React's Context API to share the current user's details and active token across all pages.
  * Persists session details in `localStorage` so users remain logged in even after closing or refreshing the tab.
  * Exposes custom hooks like `useAuth()` to check if a user is logged in and what role they hold (`ADMIN` / `STUDENT`).

---

## 🖥️ 3. React Frontend Pages & Components

### 🏠 App Route Orchestrator (`App.jsx`)
* **Where to find**: [App.jsx](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/App.jsx)
* Sets up routing using `<Routes>` and `<Route>`.
* Protects dashboard endpoints. A student cannot access the `/teacher` path because `ProtectedRoute` automatically checks user roles and redirects unauthorized requests.

### 🛡️ Protected Routes wrapper (`components/ProtectedRoute.jsx`)
* **Where to find**: [ProtectedRoute.jsx](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/components/ProtectedRoute.jsx)
* It acts as a guard. If `isAuthenticated` is false, it redirects to `/login`. If the required role doesn't match (`user.role !== role`), it redirects the user to their appropriate role-based dashboard.

### 📝 Authentication Screen (`pages/AuthPage.jsx`)
* **Where to find**: [AuthPage.jsx](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/pages/AuthPage.jsx)
* Combines Login and Registration forms.
* Uses tabs to switch between them. If registering as a `STUDENT`, it shows an input field for the student's unique academic registration number. If registering as an `ADMIN` (Teacher), that field is hidden.

### 🍎 Teacher Dashboard (`pages/TeacherDashboard.jsx` & `SessionPanel.jsx`)
* **Where to find**: [TeacherDashboard.jsx](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/pages/TeacherDashboard.jsx) and [SessionPanel.jsx](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/components/SessionPanel.jsx)
* Enables teachers to:
  1. Create classes (e.g., CSE101).
  2. Input class rosters (a list of authorized registration numbers allowed to take attendance).
  3. Start a geofenced attendance session.
* **Operation**:
  * When a teacher clicks **"Start GPS Session"**, `SessionPanel` invokes `captureCalibratedLocation` to grab the teacher's current GPS coordinate.
  * Once calibrated, the coordinates, radius (20m, 50m, 100m), and timestamp are sent to the backend `/api/sessions/start` endpoint to boot up the geofence session.
  * Shows a countdown timer of 150 seconds (the maximum attendance collection window).

### 🎓 Student Dashboard (`pages/StudentDashboard.jsx` & `ScannerPanel.jsx`)
* **Where to find**: [StudentDashboard.jsx](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/pages/StudentDashboard.jsx) and [ScannerPanel.jsx](file:///c:/Users/Qbits/Documents/attendanceSystem/frontend/src/components/ScannerPanel.jsx)
* Enables students to:
  1. Enter a 6-character class join code to join courses.
  2. View active classes and check for active attendance sessions.
  3. Give attendance inside the geofence.
* **Operation**:
  * Checks if the teacher has started an active attendance session for the selected class.
  * When the student clicks **"Give Attendance (GPS)"**, it captures the student's current location (calibrated), and sends it along with the `deviceInstallId` and session ID to the server.
  * Displays a historical table of all verified sessions the student has successfully attended.

---

## 📱 4. Flutter Mobile App Structure (`flutter_app/lib/`)

The Flutter application mirrors the React web frontend, using native widgets and native hardware access plugins.

```
flutter_app/lib/
├── main.dart                             # Flutter app entry point, initializes routes
├── models/                               # JSON serializable data models
│   ├── attendance_model.dart
│   ├── class_model.dart
│   ├── session_model.dart
│   └── user_model.dart
├── providers/                            # App state controllers (Auth/Theme)
├── screens/                              # Mobile screens
│   ├── login_screen.dart                 # Credentials and registration screen
│   ├── student_dashboard_screen.dart     # Handles student classes, GPS verification
│   └── teacher_dashboard_screen.dart     # Class creation, roster updates, session triggers
└── services/                             # Network and hardware APIs
    ├── api_service.dart                  # HTTP network client
    └── location_service.dart             # Native GPS calibration wrapper
```

### Key Flutter Services

#### 📍 1. Native Location Integration (`services/location_service.dart`)
* **Where to find**: [location_service.dart](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/services/location_service.dart)
* Checks if GPS is enabled on the device. If disabled, prompts the user to enable GPS.
* Requests OS permissions (`LocationPermission`).
* Spawns a loop that queries `Geolocator.getCurrentPosition` with `LocationAccuracy.bestForNavigation` up to 6 times.
* Compares error margins to find the best signal lock. If the accuracy is worse than the target radius, it errors and requests that the student stand still or move near a window to establish satellite connections.

#### 🔌 2. API Communication (`services/api_service.dart`)
* **Where to find**: [api_service.dart](file:///c:/Users/Qbits/Documents/attendanceSystem/flutter_app/lib/services/api_service.dart)
* Uses Dart’s `http` client.
* Maps standard API calls: `login`, `register`, `getClasses`, `startGpsSession`, `stopSession`, `claimAttendance`, and history requests.
* Packs payload fields inside raw JSON bodies and attaches Bearer authorization headers before transit.
