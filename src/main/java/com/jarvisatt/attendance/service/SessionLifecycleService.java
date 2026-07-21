package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.ClassSession;
import com.jarvisatt.attendance.domain.ClassSessionStatus;
import com.jarvisatt.attendance.dto.SessionDtos.*;
import com.jarvisatt.attendance.exception.ApiException;
import com.jarvisatt.attendance.repository.ClassSessionRepository;
import com.jarvisatt.attendance.security.UserPrincipal;
import com.jarvisatt.attendance.session.SessionEngine;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SessionLifecycleService {
    private final ClassService classService;
    private final ClassSessionRepository classSessionRepository;
    private final SessionEngine sessionEngine;

    @Transactional
    public SessionResponse start(StartSessionRequest request, UserPrincipal teacher) {
        var classEntity = classService.ownedClass(request.classId(), teacher);
        classSessionRepository.findFirstByClassEntityIdAndStatus(classEntity.getId(), ClassSessionStatus.ACTIVE)
                .ifPresent(existing -> {
                    // A session is only genuinely active if its tick timer is still
                    // running in memory. If not (e.g. the process restarted), it is
                    // orphaned — end it so the teacher can start a fresh one.
                    if (sessionEngine.isRunning(existing.getId())) {
                        throw new ApiException(HttpStatus.CONFLICT, "Class already has an active attendance session");
                    }
                    existing.setStatus(ClassSessionStatus.ENDED);
                    existing.setEndedAt(OffsetDateTime.now());
                    classSessionRepository.saveAndFlush(existing);
                });
        int totalTicks = request.totalTicks() == null ? 4 : request.totalTicks();
        int intervalSeconds = request.intervalSeconds() == null ? 3 : request.intervalSeconds();
        if (totalTicks < 1 || intervalSeconds < 1) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "totalTicks and intervalSeconds must be positive");
        }
        ClassSession session = new ClassSession();
        session.setClassEntity(classEntity);
        session.setStartedAt(OffsetDateTime.now());
        session.setStatus(ClassSessionStatus.ACTIVE);
        session.setTotalTicks(totalTicks);
        session.setTickIntervalSeconds(intervalSeconds);
        classSessionRepository.saveAndFlush(session);
        sessionEngine.start(session);
        return response(session);
    }

    public void stop(UUID sessionId, UserPrincipal teacher) {
        ClassSession session = classSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Session not found"));
        classService.ownedClass(session.getClassEntity().getId(), teacher);
        sessionEngine.stop(sessionId);
    }

    private SessionResponse response(ClassSession session) {
        return new SessionResponse(session.getId(), session.getClassEntity().getId(), session.getStatus().name(),
                session.getTotalTicks(), session.getTickIntervalSeconds());
    }
}
