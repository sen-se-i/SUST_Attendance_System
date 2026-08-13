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
                    if (sessionEngine.isRunning(existing.getId())) {
                        throw new ApiException(HttpStatus.CONFLICT, "Class already has an active attendance session");
                    }
                    existing.setStatus(ClassSessionStatus.ENDED);
                    existing.setEndedAt(OffsetDateTime.now());
                    classSessionRepository.saveAndFlush(existing);
                });

        double radiusMeters = request.radiusMeters() != null ? request.radiusMeters() : 10.0;
        double latitude = requireValidLatitude(request.latitude(), "Teacher latitude");
        double longitude = requireValidLongitude(request.longitude(), "Teacher longitude");
        if (radiusMeters <= 0 || radiusMeters > 500) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Radius must be between 1 and 500 meters");
        }

        ClassSession session = new ClassSession();
        session.setClassEntity(classEntity);
        session.setStartedAt(OffsetDateTime.now());
        session.setStatus(ClassSessionStatus.ACTIVE);
        session.setTotalTicks(150);
        session.setTickIntervalSeconds(1);
        session.setLatitude(latitude);
        session.setLongitude(longitude);
        session.setRadiusMeters(radiusMeters);

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

    @Transactional(readOnly = true)
    public SessionResponse activeSession(UUID classId) {
        ClassSession session = classSessionRepository.findFirstByClassEntityIdAndStatus(classId, ClassSessionStatus.ACTIVE)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "No active session for this class"));
        if (session.getStartedAt().plusSeconds(150).isBefore(OffsetDateTime.now())) {
            sessionEngine.stop(session.getId());
            throw new ApiException(HttpStatus.NOT_FOUND, "No active session for this class");
        }
        return response(session);
    }

    public SessionResponse response(ClassSession session) {
        OffsetDateTime startedAt = session.getStartedAt();
        OffsetDateTime expiresAt = startedAt.plusSeconds(150);
        return new SessionResponse(
                session.getId(),
                session.getClassEntity().getId(),
                session.getStatus().name(),
                session.getLatitude(),
                session.getLongitude(),
                session.getRadiusMeters(),
                startedAt,
                expiresAt
        );
    }

    private static double requireValidLatitude(Double latitude, String label) {
        if (latitude == null || !Double.isFinite(latitude) || latitude < -90.0 || latitude > 90.0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, label + " is required and must be between -90 and 90");
        }
        return latitude;
    }

    private static double requireValidLongitude(Double longitude, String label) {
        if (longitude == null || !Double.isFinite(longitude) || longitude < -180.0 || longitude > 180.0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, label + " is required and must be between -180 and 180");
        }
        return longitude;
    }
}
