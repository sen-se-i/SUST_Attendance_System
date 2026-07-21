package com.jarvisatt.attendance.repository;

import com.jarvisatt.attendance.domain.ClassSession;
import com.jarvisatt.attendance.domain.ClassSessionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

public interface ClassSessionRepository extends JpaRepository<ClassSession, UUID> {
    Optional<ClassSession> findFirstByClassEntityIdAndStatus(UUID classId, ClassSessionStatus status);

    @Modifying
    @Query("update ClassSession s set s.status = :ended, s.endedAt = :now where s.status = :active")
    int endSessionsInStatus(@Param("active") ClassSessionStatus active,
                            @Param("ended") ClassSessionStatus ended,
                            @Param("now") OffsetDateTime now);
}
