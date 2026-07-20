package com.jarvisatt.attendance.repository;

import com.jarvisatt.attendance.domain.Enrollment;
import com.jarvisatt.attendance.domain.EnrollmentStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface EnrollmentRepository extends JpaRepository<Enrollment, UUID> {
    Optional<Enrollment> findByClassEntityIdAndStudentId(UUID classId, UUID studentId);
    boolean existsByClassEntityIdAndStudentIdAndStatus(UUID classId, UUID studentId, EnrollmentStatus status);
    List<Enrollment> findByStudentIdAndStatus(UUID studentId, EnrollmentStatus status);
}
