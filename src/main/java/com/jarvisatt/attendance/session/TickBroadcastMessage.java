package com.jarvisatt.attendance.session;

import java.time.OffsetDateTime;
import java.util.UUID;

public record TickBroadcastMessage(UUID sessionId, int tickIndex, String qrPayload, OffsetDateTime expiresAt) {}
