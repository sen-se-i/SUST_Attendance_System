package com.jarvisatt.attendance.dto;

import com.jarvisatt.attendance.domain.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public final class AuthDtos {
    private AuthDtos() {}

    public record RegisterRequest(String email, @NotBlank String password, @NotNull Role role, String registrationNo, String deviceInstallId) {}
    public record LoginRequest(@NotBlank String email, @NotBlank String password, String deviceInstallId) {}
    public record AuthResponse(String token, UUID userId, String email, Role role, String registrationNo) {}
    public record UserProfileResponse(UUID userId, String email, Role role, String registrationNo, String department) {}
    public record ResetPasswordRequest(@NotBlank String registrationNo, @NotBlank String newPassword) {}
    public record CreateStudentRequest(@NotBlank String registrationNo, @NotBlank String password) {}
    public record CreateTeacherRequest(@NotBlank @email String email, @NotBlank String password, @NotBlank String department) {}
    public record AdminResetPasswordRequest(@NotBlank String identifier, @NotBlank String newPassword) {}
    public record UserSummaryResponse(UUID id, String email, Role role, String registrationNo, String department, String academicSession) {}
}

