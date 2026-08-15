package com.jarvisatt.attendance.controller;

import com.jarvisatt.attendance.dto.AuthDtos.*;
import com.jarvisatt.attendance.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    private final AuthService authService;

    @PostMapping("/register")
    AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
    AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @GetMapping("/me")
    UserProfileResponse profile(@org.springframework.security.core.annotation.AuthenticationPrincipal com.jarvisatt.attendance.security.UserPrincipal principal) {
        return authService.profile(principal);
    }

    @PostMapping("/reset-password")
    void resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request);
    }

    @DeleteMapping("/users/{target}")
    @PreAuthorize("hasRole('ADMIN')")
    void deleteUser(@PathVariable String target) {
        authService.deleteUserByEmailOrRegistrationNo(target);
    }
}
