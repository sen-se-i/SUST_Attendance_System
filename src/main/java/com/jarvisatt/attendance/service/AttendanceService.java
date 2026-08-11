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
import org.springframework.context.event.EventListener;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.time.OffsetDateTime;
import java.util.List;
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

        double teacherLat = session.getLatitude() != null ? session.getLatitude() : 0.0;
        double teacherLon = session.getLongitude() != null ? session.getLongitude() : 0.0;
        double studentLat = request.latitude();
        double studentLon = request.longitude();
        double maxRadius = session.getRadiusMeters() != null ? session.getRadiusMeters() : 10.0;

        double distanceMeters = calculateHaversineDistance(teacherLat, teacherLon, studentLat, studentLon);

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
        record.setVerificationStatus("VERIFIED");
        record.setDeviceInstallId(request.deviceInstallId());
        record.setScannedAt(OffsetDateTime.now());

        try {
            attendanceRecordRepository.saveAndFlush(record);
        } catch (DataIntegrityViolationException ex) {
            throw new ApiException(HttpStatus.CONFLICT, "Attendance already registered for this session");
        }
        upsertDevice(student, request.deviceInstallId());
        eventPublisher.publishEvent(new AttendanceConfirmedEvent(record.getId()));
        return new VerifyScanResponse(record.getId(), session.getId(), registrationNo, distanceMeters, "VERIFIED", record.getScannedAt());
    }

    @Transactional
    public VerifyScanResponse verify(VerifyScanRequest request, UserPrincipal principal) {
        if (request.sessionId() != null && request.latitude() != null && request.longitude() != null) {
            return claim(new ClaimAttendanceRequest(request.sessionId(), request.latitude(), request.longitude(), request.deviceInstallId()), principal);
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

        AttendanceRecord record = new AttendanceRecord();
        record.setSession(session);
        record.setClassEntity(session.getClassEntity());
        record.setRegistrationNo(registrationNo);
        record.setStudent(student);
        record.setScannedTick(tick);
        record.setDeviceInstallId(request.deviceInstallId());
        record.setScannedAt(OffsetDateTime.now());
        record.setDistanceMeters(0.0);
        record.setVerificationStatus("VERIFIED");
        try {
            attendanceRecordRepository.saveAndFlush(record);
        } catch (DataIntegrityViolationException ex) {
            throw new ApiException(HttpStatus.CONFLICT, "Already marked present");
        }
        upsertDevice(student, request.deviceInstallId());
        eventPublisher.publishEvent(new AttendanceConfirmedEvent(record.getId()));
        return new VerifyScanResponse(record.getId(), session.getId(), registrationNo, 0.0, "VERIFIED", record.getScannedAt());
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
                record.getScannedAt()
        );
    }

    private void upsertDevice(User student, String installId) {
        Device device = deviceRepository.findByInstallId(installId).orElseGet(Device::new);
        device.setStudent(student);
        device.setInstallId(installId);
        device.setLastSeen(OffsetDateTime.now());
        deviceRepository.save(device);
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
