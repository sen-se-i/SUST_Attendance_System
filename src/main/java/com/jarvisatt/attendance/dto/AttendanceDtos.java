package com.jarvisatt.attendance.dto;

import jakarta.validation.constraints.NotBlank;

import java.time.OffsetDateTime;
import java.util.UUID;

public final class AttendanceDtos {
    private AttendanceDtos() {}

    public record VerifyScanRequest(@NotBlank String qrPayload, @NotBlank String deviceInstallId, String attestationToken) {}
    public record VerifyScanResponse(UUID attendanceId, UUID sessionId, String registrationNo, OffsetDateTime scannedAt) {}
    public record AttendanceRecordResponse(UUID id, UUID sessionId, UUID classId, String registrationNo, String subjectCode, OffsetDateTime scannedAt) {}
}
