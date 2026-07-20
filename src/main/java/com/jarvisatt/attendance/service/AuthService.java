package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.Role;
import com.jarvisatt.attendance.domain.User;
import com.jarvisatt.attendance.dto.AuthDtos.*;
import com.jarvisatt.attendance.exception.ApiException;
import com.jarvisatt.attendance.repository.UserRepository;
import com.jarvisatt.attendance.security.JwtService;
import com.jarvisatt.attendance.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new ApiException(HttpStatus.CONFLICT, "Email already registered");
        }
        if (request.role() == Role.STUDENT && (request.registrationNo() == null || request.registrationNo().isBlank())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Student registration number is required");
        }
        User user = new User();
        user.setEmail(request.email().trim().toLowerCase());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setRole(request.role());
        user.setRegistrationNo(request.role() == Role.STUDENT ? request.registrationNo().trim() : null);
        userRepository.save(user);
        return authResponse(user);
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.email().trim().toLowerCase())
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
        }
        return authResponse(user);
    }

    private AuthResponse authResponse(User user) {
        String token = jwtService.issue(UserPrincipal.from(user));
        return new AuthResponse(token, user.getId(), user.getRole(), user.getRegistrationNo());
    }
}
