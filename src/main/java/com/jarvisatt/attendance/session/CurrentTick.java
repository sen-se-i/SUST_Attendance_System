package com.jarvisatt.attendance.session;

import java.time.OffsetDateTime;
import java.util.UUID;

public record CurrentTick(UUID tickId, int tickIndex, String tokenHash, String qrPayload, OffsetDateTime expiresAt) {}
