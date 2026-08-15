package com.jarvisatt.attendance.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;
import java.time.OffsetDateTime;

public final class SessionDtos {
    private SessionDtos() {}

    public record StartSessionRequest(
            @NotNull UUID classId,
            Double latitude,
            Double longitude,
            Double accuracyMeters,
            OffsetDateTime capturedAt,
            Double radiusMeters,
            Integer totalTicks,
            Integer intervalSeconds
    ) {}

    public record SessionResponse(
            UUID sessionId,
            UUID classId,
            String status,
            Double latitude,
            Double longitude,
            Double accuracyMeters,
            Double radiusMeters,
            OffsetDateTime startedAt,
            OffsetDateTime expiresAt
    ) {}

    public record CurrentTickResponse(
            UUID sessionId,
            Integer tickIndex,
            String qrPayload,
            String status,
            OffsetDateTime expiresAt,
            Double latitude,
            Double longitude,
            Double accuracyMeters,
            Double radiusMeters
    ) {}

    /** Lightweight record used in the teacher's class session history table. */
    public record SessionHistoryResponse(
            UUID sessionId,
            String status,
            OffsetDateTime startedAt,
            OffsetDateTime endedAt,
            Double radiusMeters,
            int attendanceCount
    ) {}
}
