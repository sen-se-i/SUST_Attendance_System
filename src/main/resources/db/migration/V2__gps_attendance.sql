-- Migration V2: Update schema for GPS Location Attendance

ALTER TABLE class_sessions ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE class_sessions ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE class_sessions ADD COLUMN IF NOT EXISTS radius_meters DOUBLE PRECISION DEFAULT 10.0;

ALTER TABLE attendance_records ALTER COLUMN scanned_tick_id DROP NOT NULL;
ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS distance_meters DOUBLE PRECISION;
ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) DEFAULT 'VERIFIED';
