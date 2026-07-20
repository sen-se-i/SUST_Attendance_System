package com.jarvisatt.attendance.exception;

import java.time.OffsetDateTime;

public record ErrorResponse(String message, int status, OffsetDateTime timestamp) {}
