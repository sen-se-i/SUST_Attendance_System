package com.jarvisatt.attendance.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public final class SessionDtos {
    private SessionDtos() {}

    public record StartSessionRequest(
            @NotNull UUID classId,
            Double latitude,
            Double longitude,
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
            Double radiusMeters,
            java.time.OffsetDateTime startedAt,
            java.time.OffsetDateTime expiresAt
    ) {}

    public record CurrentTickResponse(
            UUID sessionId,
            Integer tickIndex,
            String qrPayload,
            String status,
            java.time.OffsetDateTime expiresAt,
            Double latitude,
            Double longitude,
            Double radiusMeters
    ) {}
}
