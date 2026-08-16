package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.Device;
import com.jarvisatt.attendance.domain.Role;
import com.jarvisatt.attendance.domain.User;
import com.jarvisatt.attendance.dto.AuthDtos.LoginRequest;
import com.jarvisatt.attendance.dto.AuthDtos.RegisterRequest;
import com.jarvisatt.attendance.exception.ApiException;
import com.jarvisatt.attendance.repository.DeviceRepository;
import com.jarvisatt.attendance.repository.UserRepository;
import com.jarvisatt.attendance.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class AuthAndAttendanceServiceUnitTest {

    private UserRepository userRepository;
    private DeviceRepository deviceRepository;
    private PasswordEncoder passwordEncoder;
    private JwtService jwtService;
    private AuthService authService;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        deviceRepository = mock(DeviceRepository.class);
        passwordEncoder = mock(PasswordEncoder.class);
        jwtService = mock(JwtService.class);
        authService = new AuthService(userRepository, deviceRepository, passwordEncoder, jwtService);
    }

    @Test
    void registerNewStudentWithNewDeviceSucceeds() {
        RegisterRequest request = new RegisterRequest("student@example.com", "password", Role.STUDENT, "REG-1", "device-1");
        when(userRepository.existsByEmail(any())).thenReturn(false);
        when(deviceRepository.findByInstallId("device-1")).thenReturn(Optional.empty());
        when(passwordEncoder.encode(any())).thenReturn("hashed-password");
        when(jwtService.issue(any())).thenReturn("jwt-token");

        var response = authService.register(request);
        assertThat(response.token()).isEqualTo("jwt-token");
        verify(deviceRepository, times(1)).save(any(Device.class));
    }

    @Test
    void registerStudentWithAlreadyOwnedDeviceSucceeds() {
        UUID studentId = UUID.randomUUID();
        User existingStudent = new User();
        existingStudent.setId(studentId);
        existingStudent.setRegistrationNo("REG-1");

        Device device = new Device();
        device.setStudent(existingStudent);
        device.setInstallId("device-1");

        RegisterRequest request = new RegisterRequest("student@example.com", "password", Role.STUDENT, "REG-1", "device-1");

        when(userRepository.existsByEmail(any())).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(studentId);
            return user;
        });
        when(deviceRepository.findByInstallId("device-1")).thenReturn(Optional.of(device));
        when(passwordEncoder.encode(any())).thenReturn("hashed-password");
        when(jwtService.issue(any())).thenReturn("jwt-token");

        var response = authService.register(request);
        assertThat(response.token()).isEqualTo("jwt-token");

        verify(deviceRepository, times(0)).save(any(Device.class));
    }

    @Test
    void registerStudentWithSharedDeviceFails() {
        UUID otherStudentId = UUID.randomUUID();
        User otherStudent = new User();
        otherStudent.setId(otherStudentId);
        otherStudent.setRegistrationNo("REG-other");

        Device device = new Device();
        device.setStudent(otherStudent);
        device.setInstallId("device-1");

        RegisterRequest request = new RegisterRequest("student@example.com", "password", Role.STUDENT, "REG-1", "device-1");
        when(userRepository.existsByEmail(any())).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(UUID.randomUUID());
            return user;
        });
        when(deviceRepository.findByInstallId("device-1")).thenReturn(Optional.of(device));

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).status())
                .isEqualTo(HttpStatus.CONFLICT);
    }

    @Test
    void loginWithSharedDeviceFails() {
        UUID studentId = UUID.randomUUID();
        User student = new User();
        student.setId(studentId);
        student.setEmail("student@example.com");
        student.setRole(Role.STUDENT);
        student.setPasswordHash("hashed-password");

        UUID otherStudentId = UUID.randomUUID();
        User otherStudent = new User();
        otherStudent.setId(otherStudentId);
        otherStudent.setRegistrationNo("REG-other");

        Device device = new Device();
        device.setStudent(otherStudent);
        device.setInstallId("device-1");

        LoginRequest request = new LoginRequest("student@example.com", "password", "device-1");
        when(userRepository.findByEmail(any())).thenReturn(Optional.of(student));
        when(passwordEncoder.matches(any(), any())).thenReturn(true);
        when(deviceRepository.findByInstallId("device-1")).thenReturn(Optional.of(device));

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).status())
                .isEqualTo(HttpStatus.CONFLICT);
    }
}

