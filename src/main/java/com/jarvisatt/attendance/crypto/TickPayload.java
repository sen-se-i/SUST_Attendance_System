package com.jarvisatt.attendance.crypto;

import java.util.UUID;

public record TickPayload(UUID sessionId, int tickIndex, String nonce) {}
