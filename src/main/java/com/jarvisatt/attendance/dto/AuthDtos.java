package com.jarvisatt.attendance.dto;

import com.jarvisatt.attendance.domain.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public final class AuthDtos {
    private AuthDtos() {}

    public record RegisterRequest(@Email String email, @NotBlank String password, @NotNull Role role, String registrationNo) {}
    public record LoginRequest(@Email String email, @NotBlank String password) {}
    public record AuthResponse(String token, UUID userId, Role role, String registrationNo) {}
}
