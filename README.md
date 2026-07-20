# JARVIS-ATT Backend

Spring Boot Phase 1 backend for the rotating-QR attendance system.

## What is included

- JWT auth for `ADMIN` teachers and `STUDENT` users.
- PostgreSQL schema managed by Flyway.
- Teacher class creation with 6-character join codes.
- Roster allowlist and roster-gated student join.
- Rotating QR session engine with AES-GCM opaque payloads and HMAC token hashes.
- WebSocket broadcast of active ticks at `/topic/sessions/{sessionId}/ticks`.
- Atomic attendance verification that consumes a QR tick once and writes one attendance row per student/session.
- Dev notification implementation that logs attendance confirmation after commit.

## Run locally

```powershell
docker compose up -d
$env:JAVA_HOME='C:\Program Files\Java\jdk-25'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
.\mvnw.cmd spring-boot:run
```

The API starts at `http://localhost:8080`.

## Useful API flow

1. `POST /api/auth/register` for a teacher with role `ADMIN`.
2. `POST /api/auth/register` for a student with role `STUDENT` and `registrationNo`.
3. `POST /api/classes` as teacher.
4. `POST /api/classes/{classId}/roster` as teacher.
5. `POST /api/classes/join` as student.
6. `POST /api/sessions/start` as teacher.
7. Student scanner submits `POST /api/attendance/verify`.

Use `Authorization: Bearer <token>` for all non-auth endpoints.

## Tests

```powershell
$env:JAVA_HOME='C:\Program Files\Java\jdk-25'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
.\mvnw.cmd test
```

Crypto tests always run. The Postgres end-to-end and concurrency tests use Testcontainers and are skipped automatically when Docker is not available.
