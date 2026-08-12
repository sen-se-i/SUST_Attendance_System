package com.jarvisatt.attendance.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;
import java.util.UUID;

public final class AttendanceDtos {
    private AttendanceDtos() {}

    public record VerifyScanRequest(
            String qrPayload,
            @NotBlank String deviceInstallId,
            String attestationToken,
            UUID sessionId,
            Double latitude,
            Double longitude
    ) {}

    public record ClaimAttendanceRequest(
            @NotNull UUID sessionId,
            @NotNull Double latitude,
            @NotNull Double longitude,
            @NotBlank String deviceInstallId
    ) {}

    public record VerifyScanResponse(
            UUID attendanceId,
            UUID sessionId,
            String registrationNo,
            Double distanceMeters,
            String status,
            OffsetDateTime scannedAt
    ) {}

    public record AttendanceRecordResponse(
            UUID id,
            UUID sessionId,
            UUID classId,
            String registrationNo,
            String subjectCode,
            Double distanceMeters,
            Double latitude,
            Double longitude,
            OffsetDateTime scannedAt
    ) {}
}
