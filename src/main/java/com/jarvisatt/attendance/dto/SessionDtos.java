package com.jarvisatt.attendance.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public final class SessionDtos {
    private SessionDtos() {}

    public record StartSessionRequest(@NotNull UUID classId, Integer totalTicks, Integer intervalSeconds) {}
    public record SessionResponse(UUID sessionId, UUID classId, String status, int totalTicks, int intervalSeconds) {}
    public record CurrentTickResponse(UUID sessionId, Integer tickIndex, String qrPayload, String status, java.time.OffsetDateTime expiresAt) {}
}
