CREATE TABLE users (
    id UUID PRIMARY KEY,
    role VARCHAR(20) NOT NULL CHECK (role IN ('ADMIN', 'STUDENT')),
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    registration_no TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX ux_users_registration_no ON users (registration_no);

CREATE TABLE classes (
    id UUID PRIMARY KEY,
    code VARCHAR(6) NOT NULL UNIQUE,
    department TEXT NOT NULL,
    academic_session TEXT NOT NULL,
    subject_code TEXT NOT NULL,
    teacher_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE class_roster (
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    registration_no TEXT NOT NULL,
    PRIMARY KEY (class_id, registration_no)
);

CREATE TABLE enrollments (
    id UUID PRIMARY KEY,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'ACTIVE')),
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE class_sessions (
    id UUID PRIMARY KEY,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'ENDED')),
    total_ticks INT NOT NULL DEFAULT 4,
    tick_interval_seconds INT NOT NULL DEFAULT 3
);

CREATE TABLE qr_ticks (
    id UUID PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES class_sessions(id) ON DELETE CASCADE,
    tick_index INT NOT NULL,
    token_hash TEXT NOT NULL,
    issued_at TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    consumed_by TEXT,
    consumed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE (session_id, tick_index)
);

CREATE TABLE attendance_records (
    id UUID PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES class_sessions(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    registration_no TEXT NOT NULL,
    student_id UUID NOT NULL REFERENCES users(id),
    scanned_tick_id UUID NOT NULL REFERENCES qr_ticks(id),
    device_install_id TEXT NOT NULL,
    scanned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (session_id, registration_no)
);

CREATE TABLE devices (
    id UUID PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    install_id TEXT NOT NULL UNIQUE,
    last_seen TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
