package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.crypto.AesPayloadCipher;
import com.jarvisatt.attendance.crypto.HmacTokenService;
import com.jarvisatt.attendance.crypto.TickPayload;
import com.jarvisatt.attendance.domain.*;
import com.jarvisatt.attendance.dto.AttendanceDtos.*;
import com.jarvisatt.attendance.exception.ApiException;
import com.jarvisatt.attendance.repository.*;
import com.jarvisatt.attendance.security.UserPrincipal;
import com.jarvisatt.attendance.service.notification.NotificationService;
import com.jarvisatt.attendance.session.CurrentTick;
import com.jarvisatt.attendance.session.SessionEngine;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AttendanceService {
    private final AesPayloadCipher aesPayloadCipher;
    private final HmacTokenService hmacTokenService;
    private final SessionEngine sessionEngine;
    private final QrTickRepository qrTickRepository;
    private final ClassSessionRepository classSessionRepository;
    private final ClassRosterRepository rosterRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final AttendanceRecordRepository attendanceRecordRepository;
    private final UserRepository userRepository;
    private final DeviceRepository deviceRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional
    public VerifyScanResponse claim(ClaimAttendanceRequest request, UserPrincipal principal) {
        User student = userRepository.findById(principal.id()).orElseThrow();
        String registrationNo = student.getRegistrationNo();
        if (registrationNo == null) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Only registered students can submit attendance");
        }
        ClassSession session = classSessionRepository.findById(request.sessionId())
                .orElseThrow(() -> new ApiException(HttpStatus.GONE, "Attendance session not found or ended"));

        if (session.getStatus() != ClassSessionStatus.ACTIVE) {
            throw new ApiException(HttpStatus.GONE, "Attendance session has ended");
        }
        if (session.getStartedAt().plusSeconds(150).isBefore(OffsetDateTime.now())) {
            session.setStatus(ClassSessionStatus.ENDED);
            session.setEndedAt(OffsetDateTime.now());
            classSessionRepository.saveAndFlush(session);
            throw new ApiException(HttpStatus.GONE, "Attendance session expired (150s limit reached)");
        }

        if (!rosterRepository.existsByClassIdAndRegistrationNo(session.getClassEntity().getId(), registrationNo)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Registration number not found in class roster allowlist");
        }
        if (!enrollmentRepository.existsByClassEntityIdAndStudentIdAndStatus(session.getClassEntity().getId(), student.getId(), EnrollmentStatus.ACTIVE)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Student has not joined this class");
        }
        if (attendanceRecordRepository.existsBySessionIdAndRegistrationNo(session.getId(), registrationNo)) {
            throw new ApiException(HttpStatus.CONFLICT, "Attendance already registered for this session");
        }

        double teacherLat = requireValidLatitude(session.getLatitude(), "Session latitude");
        double teacherLon = requireValidLongitude(session.getLongitude(), "Session longitude");
        double studentLat = requireValidLatitude(request.latitude(), "Student latitude");
        double studentLon = requireValidLongitude(request.longitude(), "Student longitude");
        double studentAccuracyMeters = requireValidAccuracy(request.accuracyMeters(), "Student GPS accuracy");
        double maxRadius = session.getRadiusMeters() != null ? session.getRadiusMeters() : 10.0;
        requireFreshCapture(request.capturedAt(), "Student GPS reading");

        double distanceMeters = calculateHaversineDistance(teacherLat, teacherLon, studentLat, studentLon);
        requireCalibratedInsideRadius(distanceMeters, studentAccuracyMeters, maxRadius);

        if (distanceMeters > maxRadius) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                    String.format("Location out of range! Distance from classroom: %.1fm (Allowed radius: %.1fm). Please move closer.", distanceMeters, maxRadius));
        }

        AttendanceRecord record = new AttendanceRecord();
        record.setSession(session);
        record.setClassEntity(session.getClassEntity());
        record.setRegistrationNo(registrationNo);
        record.setStudent(student);
        record.setLatitude(studentLat);
        record.setLongitude(studentLon);
        record.setDistanceMeters(distanceMeters);
        record.setAccuracyMeters(studentAccuracyMeters);
        record.setVerificationStatus("VERIFIED");
        record.setDeviceInstallId(request.deviceInstallId());
        record.setScannedAt(OffsetDateTime.now());

        upsertDevice(student, request.deviceInstallId());
        try {
            attendanceRecordRepository.saveAndFlush(record);
        } catch (DataIntegrityViolationException ex) {
            throw new ApiException(HttpStatus.CONFLICT, "Attendance already registered for this session");
        }
        eventPublisher.publishEvent(new AttendanceConfirmedEvent(record.getId()));
        return new VerifyScanResponse(record.getId(), session.getId(), registrationNo, distanceMeters, studentAccuracyMeters, "VERIFIED", record.getScannedAt());
    }

    @Transactional
    public VerifyScanResponse verify(VerifyScanRequest request, UserPrincipal principal) {
        if (request.sessionId() != null && request.latitude() != null && request.longitude() != null) {
            return claim(new ClaimAttendanceRequest(request.sessionId(), request.latitude(), request.longitude(), request.accuracyMeters(), request.capturedAt(), request.deviceInstallId()), principal);
        }
        User student = userRepository.findById(principal.id()).orElseThrow();
        String registrationNo = student.getRegistrationNo();
        if (registrationNo == null) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Only students can verify attendance");
        }
        TickPayload payload = aesPayloadCipher.decrypt(request.qrPayload());
        String tokenHash = hmacTokenService.hash(hmacTokenService.token(payload.sessionId(), payload.tickIndex(), payload.nonce()));

        CurrentTick live = sessionEngine.currentTick(payload.sessionId())
                .orElseThrow(() -> new ApiException(HttpStatus.GONE, "Session is not active"));
        if (live.tickIndex() != payload.tickIndex() || !live.tokenHash().equals(tokenHash) || live.expiresAt().isBefore(OffsetDateTime.now())) {
            throw new ApiException(HttpStatus.GONE, "Session expired, please retry");
        }

        QrTick tick = qrTickRepository.findBySessionIdAndTickIndex(payload.sessionId(), payload.tickIndex())
                .orElseThrow(() -> new ApiException(HttpStatus.GONE, "Tick not found"));
        if (!tick.getTokenHash().equals(tokenHash)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid token");
        }
        ClassSession session = classSessionRepository.findById(payload.sessionId())
                .orElseThrow(() -> new ApiException(HttpStatus.GONE, "Session not found"));
        if (!rosterRepository.existsByClassIdAndRegistrationNo(session.getClassEntity().getId(), registrationNo)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Not enrolled in this class roster");
        }
        if (!enrollmentRepository.existsByClassEntityIdAndStudentIdAndStatus(session.getClassEntity().getId(), student.getId(), EnrollmentStatus.ACTIVE)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Student has not joined this class");
        }
        if (attendanceRecordRepository.existsBySessionIdAndRegistrationNo(session.getId(), registrationNo)) {
            throw new ApiException(HttpStatus.CONFLICT, "Already marked present");
        }

        double teacherLat = requireValidLatitude(session.getLatitude(), "Session latitude");
        double teacherLon = requireValidLongitude(session.getLongitude(), "Session longitude");
        double studentLat = requireValidLatitude(request.latitude(), "Student latitude");
        double studentLon = requireValidLongitude(request.longitude(), "Student longitude");
        double studentAccuracyMeters = requireValidAccuracy(request.accuracyMeters(), "Student GPS accuracy");
        double maxRadius = session.getRadiusMeters() != null ? session.getRadiusMeters() : 10.0;
        requireFreshCapture(request.capturedAt(), "Student GPS reading");

        double distanceMeters = calculateHaversineDistance(teacherLat, teacherLon, studentLat, studentLon);
        requireCalibratedInsideRadius(distanceMeters, studentAccuracyMeters, maxRadius);

        if (distanceMeters > maxRadius) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                    String.format("Location out of range! Distance from classroom: %.1fm (Allowed radius: %.1fm). Please move closer.", distanceMeters, maxRadius));
        }

        AttendanceRecord record = new AttendanceRecord();
        record.setSession(session);
        record.setClassEntity(session.getClassEntity());
        record.setRegistrationNo(registrationNo);
        record.setStudent(student);
        record.setScannedTick(tick);
        record.setLatitude(studentLat);
        record.setLongitude(studentLon);
        record.setDistanceMeters(distanceMeters);
        record.setAccuracyMeters(studentAccuracyMeters);
        record.setVerificationStatus("VERIFIED");
        record.setDeviceInstallId(request.deviceInstallId());
        record.setScannedAt(OffsetDateTime.now());
        upsertDevice(student, request.deviceInstallId());
        try {
            attendanceRecordRepository.saveAndFlush(record);
        } catch (DataIntegrityViolationException ex) {
            throw new ApiException(HttpStatus.CONFLICT, "Already marked present");
        }
        eventPublisher.publishEvent(new AttendanceConfirmedEvent(record.getId()));
        return new VerifyScanResponse(record.getId(), session.getId(), registrationNo, distanceMeters, studentAccuracyMeters, "VERIFIED", record.getScannedAt());
    }

    public static double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
        final double EARTH_RADIUS_METERS = 6371000.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_METERS * c;
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

    private static void requireCalibratedInsideRadius(double distanceMeters, double accuracyMeters, double radiusMeters) {
        if (accuracyMeters > radiusMeters) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                    String.format("GPS accuracy is %.1fm, too weak for a %.1fm attendance radius. Wait for a stronger GPS fix and try again.", accuracyMeters, radiusMeters));
        }
        if (distanceMeters + accuracyMeters > radiusMeters) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                    String.format("Location cannot be verified inside the classroom radius. Distance: %.1fm, GPS accuracy: +/-%.1fm, allowed radius: %.1fm.", distanceMeters, accuracyMeters, radiusMeters));
        }
    }

    @Transactional(readOnly = true)
    public List<AttendanceRecordResponse> studentHistory(UserPrincipal principal) {
        return attendanceRecordRepository.findByStudentIdOrderByScannedAtDesc(principal.id()).stream()
                .map(this::response)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AttendanceRecordResponse> classHistory(UUID classId, UserPrincipal teacher) {
        return attendanceRecordRepository.findByClassEntityIdOrderByScannedAtDesc(classId).stream()
                .filter(record -> record.getClassEntity().getTeacher().getId().equals(teacher.id()))
                .map(this::response)
                .toList();
    }

    private AttendanceRecordResponse response(AttendanceRecord record) {
        return new AttendanceRecordResponse(
                record.getId(),
                record.getSession().getId(),
                record.getClassEntity().getId(),
                record.getRegistrationNo(),
                record.getClassEntity().getSubjectCode(),
                record.getDistanceMeters(),
                record.getLatitude(),
                record.getLongitude(),
                record.getAccuracyMeters(),
                record.getScannedAt()
        );
    }

    private void upsertDevice(User student, String installId) {
        if (installId == null || installId.isBlank()) {
            return;
        }
        Optional<Device> existingDevice = deviceRepository.findByInstallId(installId);
        if (existingDevice.isPresent()) {
            User registeredStudent = existingDevice.get().getStudent();
            if (!registeredStudent.getId().equals(student.getId())) {
                throw new ApiException(HttpStatus.CONFLICT,
                        "This device is already registered to another student (" + registeredStudent.getRegistrationNo() + "). Sharing devices is not allowed.");
            }
            Device device = existingDevice.get();
            device.setLastSeen(OffsetDateTime.now());
            deviceRepository.save(device);
        } else {
            Device device = new Device();
            device.setStudent(student);
            device.setInstallId(installId);
            device.setLastSeen(OffsetDateTime.now());
            deviceRepository.save(device);
        }
    }

    public record AttendanceConfirmedEvent(java.util.UUID recordId) {}

    @Service
    @RequiredArgsConstructor
    public static class AttendanceNotificationListener {
        private final AttendanceRecordRepository attendanceRecordRepository;
        private final NotificationService notificationService;

        @Async
        @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
        public void confirmed(AttendanceConfirmedEvent event) {
            attendanceRecordRepository.findById(event.recordId()).ifPresent(notificationService::attendanceConfirmed);
        }
    }
}
