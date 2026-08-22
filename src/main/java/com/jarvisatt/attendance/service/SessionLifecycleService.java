package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.ClassSession;
import com.jarvisatt.attendance.domain.ClassSessionStatus;
import com.jarvisatt.attendance.domain.EnrollmentStatus;
import com.jarvisatt.attendance.domain.Role;
import com.jarvisatt.attendance.dto.SessionDtos.*;
import com.jarvisatt.attendance.exception.ApiException;
import com.jarvisatt.attendance.repository.AttendanceRecordRepository;
import com.jarvisatt.attendance.repository.ClassSessionRepository;
import com.jarvisatt.attendance.repository.EnrollmentRepository;
import com.jarvisatt.attendance.security.UserPrincipal;
import com.jarvisatt.attendance.session.SessionEngine;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SessionLifecycleService {
    private final ClassService classService;
    private final ClassSessionRepository classSessionRepository;
    private final AttendanceRecordRepository attendanceRecordRepository;
    private final EnrollmentRepository enrollmentRepository;
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
        double accuracyMeters = requireValidAccuracy(request.accuracyMeters(), "Teacher GPS accuracy");
        requireNonZeroCoordinates(latitude, longitude, "Teacher GPS location");
        requireFreshCapture(request.capturedAt(), "Teacher GPS reading");
        if (radiusMeters <= 0 || radiusMeters > 500) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Radius must be between 1 and 500 meters");
        }
        requireAccuracySuitableForRadius(accuracyMeters, radiusMeters, "Teacher GPS accuracy");

        ClassSession session = new ClassSession();
        session.setClassEntity(classEntity);
        session.setStartedAt(OffsetDateTime.now());
        session.setStatus(ClassSessionStatus.ACTIVE);
        session.setTotalTicks(150);
        session.setTickIntervalSeconds(1);
        session.setLatitude(latitude);
        session.setLongitude(longitude);
        session.setAccuracyMeters(accuracyMeters);
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

    @Transactional(readOnly = true)
    public List<SessionHistoryResponse> listByClass(UUID classId, UserPrincipal principal) {
        if (principal.role() == Role.ADMIN) {
            classService.ownedClass(classId, principal);
        } else {
            if (!enrollmentRepository.existsByClassEntityIdAndStudentIdAndStatus(classId, principal.id(), EnrollmentStatus.ACTIVE)) {
                throw new ApiException(HttpStatus.FORBIDDEN, "You are not enrolled in this class");
            }
        }
        return classSessionRepository.findByClassEntityIdOrderByStartedAtDesc(classId).stream()
                .map(s -> {
                    long count = attendanceRecordRepository.countBySessionId(s.getId());
                    return new SessionHistoryResponse(
                            s.getId(),
                            s.getStatus().name(),
                            s.getStartedAt(),
                            s.getEndedAt(),
                            s.getRadiusMeters(),
                            count);
                })
                .toList();
    }

    @Transactional
    public void deleteSession(UUID sessionId, UserPrincipal teacher) {
        ClassSession session = classSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Session not found"));
        classService.ownedClass(session.getClassEntity().getId(), teacher);
        sessionEngine.stop(sessionId);
        attendanceRecordRepository.deleteBySessionId(sessionId);
        classSessionRepository.deleteById(sessionId);
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
                session.getAccuracyMeters(),
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

    private static void requireNonZeroCoordinates(Double latitude, Double longitude, String label) {
        if (latitude != null && longitude != null && Math.abs(latitude) < 0.000001 && Math.abs(longitude) < 0.000001) {
            throw new ApiException(HttpStatus.BAD_REQUEST, label + " returned invalid (0,0) coordinates. Please enable device location / GPS and try again.");
        }
    }

    private static double requireValidAccuracy(Double accuracyMeters, String label) {
        if (accuracyMeters == null || !Double.isFinite(accuracyMeters) || accuracyMeters <= 0.0 || accuracyMeters > 100.0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, label + " is required and must be between 0 and 100 meters");
        }
        return accuracyMeters;
    }

    private static void requireFreshCapture(OffsetDateTime capturedAt, String label) {
        OffsetDateTime now = OffsetDateTime.now();
        if (capturedAt == null || capturedAt.isBefore(now.minusSeconds(15)) || capturedAt.isAfter(now.plusSeconds(30))) {
            throw new ApiException(HttpStatus.BAD_REQUEST, label + " must be freshly captured within the last 15 seconds");
        }
    }

    private static void requireAccuracySuitableForRadius(double accuracyMeters, double radiusMeters, String label) {
        double maxAllowedAccuracy = Math.max(3.0, radiusMeters);
        if (accuracyMeters > maxAllowedAccuracy) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                    String.format("%s is %.1fm, which is too weak for a %.1fm geofence. Wait for a stronger GPS fix and try again.", label, accuracyMeters, radiusMeters));
        }
    }
}

