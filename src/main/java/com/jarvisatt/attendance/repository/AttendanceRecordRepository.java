package com.jarvisatt.attendance.repository;

import com.jarvisatt.attendance.domain.AttendanceRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AttendanceRecordRepository extends JpaRepository<AttendanceRecord, UUID> {
    boolean existsBySessionIdAndRegistrationNo(UUID sessionId, String registrationNo);
    long countBySessionId(UUID sessionId);
    List<AttendanceRecord> findByStudentIdOrderByScannedAtDesc(UUID studentId);
    List<AttendanceRecord> findByClassEntityIdOrderByScannedAtDesc(UUID classId);
}
