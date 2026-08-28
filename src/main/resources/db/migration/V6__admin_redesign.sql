-- Migration V6: Admin Redesign, New Roles, User Dept/Session, Class Status

-- Drop old check constraint on role if exists, then allow TEACHER
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('ADMIN', 'TEACHER', 'STUDENT'));

-- Make email nullable for students who only have registrationNo
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

-- Add department and academic session to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS department VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS academic_session VARCHAR(50);

-- Add status to classes (ACTIVE, ENDED)
ALTER TABLE classes ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'ACTIVE';
