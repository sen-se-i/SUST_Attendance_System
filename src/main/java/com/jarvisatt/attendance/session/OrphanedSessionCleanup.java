package com.jarvisatt.attendance.session;

import com.jarvisatt.attendance.domain.ClassSessionStatus;
import com.jarvisatt.attendance.repository.ClassSessionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

/**
 * The rotating-tick engine keeps session timers in memory. When the process
 * restarts (deploys, or the free host spinning down when idle), those timers are
 * lost but the database still marks sessions ACTIVE. Such sessions can never
 * produce ticks again and would block a class from starting a new session, so we
 * end any leftover ACTIVE sessions on startup.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class OrphanedSessionCleanup {
    private final ClassSessionRepository classSessionRepository;

    @EventListener(ApplicationReadyEvent.class)
    @Transactional
    public void endOrphanedSessions() {
        int ended = classSessionRepository.endSessionsInStatus(
                ClassSessionStatus.ACTIVE, ClassSessionStatus.ENDED, OffsetDateTime.now());
        if (ended > 0) {
            log.info("Ended {} orphaned attendance session(s) left ACTIVE from a previous run", ended);
        }
    }
}
