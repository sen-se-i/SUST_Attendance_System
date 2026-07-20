package com.jarvisatt.attendance.repository;

import com.jarvisatt.attendance.domain.QrTick;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

public interface QrTickRepository extends JpaRepository<QrTick, UUID> {
    Optional<QrTick> findBySessionIdAndTickIndex(UUID sessionId, int tickIndex);

    @Modifying
    @Query("""
        update QrTick q
           set q.consumedBy = :registrationNo, q.consumedAt = :now
         where q.id = :id
           and q.consumedBy is null
           and q.expiresAt > :now
        """)
    int consumeIfAvailable(@Param("id") UUID id, @Param("registrationNo") String registrationNo, @Param("now") OffsetDateTime now);

    @Modifying
    @Query("update QrTick q set q.expiresAt = :now where q.id = :id and q.expiresAt > :now")
    int expireNow(@Param("id") UUID id, @Param("now") OffsetDateTime now);
}
