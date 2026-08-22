-- Persist GPS accuracy so tight geofence decisions can be audited.
ALTER TABLE class_sessions ADD COLUMN IF NOT EXISTS accuracy_meters DOUBLE PRECISION;
ALTER TABLE attendance_records ADD COLUMN IF NOT EXISTS accuracy_meters DOUBLE PRECISION;
