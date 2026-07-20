package com.jarvisatt.attendance.repository;

import com.jarvisatt.attendance.domain.ClassSession;
import com.jarvisatt.attendance.domain.ClassSessionStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface ClassSessionRepository extends JpaRepository<ClassSession, UUID> {
    Optional<ClassSession> findFirstByClassEntityIdAndStatus(UUID classId, ClassSessionStatus status);
}
