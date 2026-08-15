package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.Role;
import com.jarvisatt.attendance.domain.User;
import com.jarvisatt.attendance.domain.Device;
import com.jarvisatt.attendance.dto.AuthDtos.*;
import com.jarvisatt.attendance.exception.ApiException;
import com.jarvisatt.attendance.repository.UserRepository;
import com.jarvisatt.attendance.repository.DeviceRepository;
import com.jarvisatt.attendance.security.JwtService;
import com.jarvisatt.attendance.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final DeviceRepository deviceRepository;
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

        if (request.role() == Role.STUDENT && request.deviceInstallId() != null && !request.deviceInstallId().isBlank()) {
            Optional<Device> existingDevice = deviceRepository.findByInstallId(request.deviceInstallId());
            if (existingDevice.isPresent()) {
                User registeredStudent = existingDevice.get().getStudent();
                if (!registeredStudent.getId().equals(user.getId())) {
                    throw new ApiException(HttpStatus.CONFLICT,
                            "This device is already registered to another student (" + registeredStudent.getRegistrationNo() + "). Sharing devices is not allowed.");
                }
            } else {
                Device device = new Device();
                device.setStudent(user);
                device.setInstallId(request.deviceInstallId());
                device.setLastSeen(OffsetDateTime.now());
                deviceRepository.save(device);
            }
        }

        return authResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.email().trim().toLowerCase())
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
        }

        if (user.getRole() == Role.STUDENT && request.deviceInstallId() != null && !request.deviceInstallId().isBlank()) {
            Optional<Device> existingDevice = deviceRepository.findByInstallId(request.deviceInstallId());
            if (existingDevice.isPresent()) {
                User registeredStudent = existingDevice.get().getStudent();
                if (!registeredStudent.getId().equals(user.getId())) {
                    throw new ApiException(HttpStatus.CONFLICT,
                            "This device is already registered to another student (" + registeredStudent.getRegistrationNo() + "). Sharing devices is not allowed.");
                }
            } else {
                Device device = new Device();
                device.setStudent(user);
                device.setInstallId(request.deviceInstallId());
                device.setLastSeen(OffsetDateTime.now());
                deviceRepository.save(device);
            }
        }

        return authResponse(user);
    }

    @Transactional(readOnly = true)
    public UserProfileResponse profile(UserPrincipal principal) {
        User user = userRepository.findById(principal.id()).orElseThrow();
        String dept = user.getRole() == Role.STUDENT ? "Software Engineering" : "Software Engineering / Faculty";
        return new UserProfileResponse(user.getId(), user.getEmail(), user.getRole(), user.getRegistrationNo(), dept);
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        User user = userRepository.findByRegistrationNo(request.registrationNo().trim())
                .or(() -> userRepository.findByEmail(request.registrationNo().trim().toLowerCase()))
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Account not found for: " + request.registrationNo()));
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
        deviceRepository.deleteByStudentId(user.getId());
    }

    private final EnrollmentRepository enrollmentRepository;
    private final AttendanceRecordRepository attendanceRecordRepository;

    @Transactional
    public void deleteUserByEmailOrRegistrationNo(String target) {
        User user = userRepository.findByEmail(target.trim().toLowerCase())
                .or(() -> userRepository.findByRegistrationNo(target.trim()))
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User account not found for: " + target));

        deviceRepository.deleteByStudentId(user.getId());
        enrollmentRepository.deleteByStudentId(user.getId());
        attendanceRecordRepository.deleteByStudentId(user.getId());
        userRepository.delete(user);
    }

    private AuthResponse authResponse(User user) {
        String token = jwtService.issue(UserPrincipal.from(user));
        return new AuthResponse(token, user.getId(), user.getEmail(), user.getRole(), user.getRegistrationNo());
    }
}
