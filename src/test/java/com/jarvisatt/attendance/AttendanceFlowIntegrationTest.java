package com.jarvisatt.attendance;

import com.jarvisatt.attendance.domain.Role;
import com.jarvisatt.attendance.dto.AttendanceDtos.VerifyScanRequest;
import com.jarvisatt.attendance.dto.AuthDtos.RegisterRequest;
import com.jarvisatt.attendance.dto.ClassDtos.CreateClassRequest;
import com.jarvisatt.attendance.dto.ClassDtos.JoinClassRequest;
import com.jarvisatt.attendance.dto.ClassDtos.RosterRequest;
import com.jarvisatt.attendance.dto.SessionDtos.StartSessionRequest;
import com.jarvisatt.attendance.exception.ApiException;
import com.jarvisatt.attendance.repository.AttendanceRecordRepository;
import com.jarvisatt.attendance.repository.QrTickRepository;
import com.jarvisatt.attendance.security.UserPrincipal;
import com.jarvisatt.attendance.service.*;
import com.jarvisatt.attendance.session.SessionEngine;
import org.awaitility.Awaitility;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.time.Duration;
import java.util.List;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Testcontainers(disabledWithoutDocker = true)
class AttendanceFlowIntegrationTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>(DockerImageName.parse("postgres:16-alpine"));

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired AuthService authService;
    @Autowired ClassService classService;
    @Autowired RosterService rosterService;
    @Autowired EnrollmentService enrollmentService;
    @Autowired SessionLifecycleService sessionLifecycleService;
    @Autowired AttendanceService attendanceService;
    @Autowired SessionEngine sessionEngine;
    @Autowired AttendanceRecordRepository attendanceRecordRepository;
    @Autowired QrTickRepository qrTickRepository;

    @Test
    void fullFlowAcceptsScanOnceAndRejectsReplay() {
        Fixture fixture = fixture("once");
        String payload = activePayload(fixture);

        var response = attendanceService.verify(new VerifyScanRequest(payload, "device-once", null), fixture.student());
        assertThat(response.registrationNo()).isEqualTo("REG-once");

        assertThatThrownBy(() -> attendanceService.verify(new VerifyScanRequest(payload, "device-once", null), fixture.student()))
                .isInstanceOf(ApiException.class)
                .extracting(ex -> ((ApiException) ex).status())
                .isEqualTo(HttpStatus.CONFLICT);
        assertThat(attendanceRecordRepository.countBySessionId(fixture.session().sessionId())).isEqualTo(1);
    }

    @Test
    void concurrentScansOnlyConsumeTickOnce() throws Exception {
        Fixture fixture = fixture("race");
        String payload = activePayload(fixture);
        int attempts = 12;
        ExecutorService executor = Executors.newFixedThreadPool(attempts);
        CountDownLatch ready = new CountDownLatch(attempts);
        CountDownLatch start = new CountDownLatch(1);
        AtomicInteger successes = new AtomicInteger();
        List<Future<Object>> futures = java.util.stream.IntStream.range(0, attempts)
                .mapToObj(i -> executor.submit(() -> {
                    ready.countDown();
                    start.await(2, TimeUnit.SECONDS);
                    try {
                        attendanceService.verify(new VerifyScanRequest(payload, "device-race-" + i, null), fixture.student());
                        successes.incrementAndGet();
                    } catch (ApiException ignored) {
                    }
                    return null;
                }))
                .toList();
        assertThat(ready.await(2, TimeUnit.SECONDS)).isTrue();
        start.countDown();
        for (Future<Object> future : futures) {
            future.get(5, TimeUnit.SECONDS);
        }
        executor.shutdownNow();

        assertThat(successes.get()).isEqualTo(1);
        assertThat(attendanceRecordRepository.countBySessionId(fixture.session().sessionId())).isEqualTo(1);
        var consumed = qrTickRepository.findBySessionIdAndTickIndex(fixture.session().sessionId(), 0).orElseThrow();
        assertThat(consumed.getConsumedBy()).isEqualTo("REG-race");
    }

    private Fixture fixture(String suffix) {
        var teacherAuth = authService.register(new RegisterRequest("teacher-" + suffix + "@example.com", "password", Role.ADMIN, null));
        var studentAuth = authService.register(new RegisterRequest("student-" + suffix + "@example.com", "password", Role.STUDENT, "REG-" + suffix));
        UserPrincipal teacher = new UserPrincipal(teacherAuth.userId(), "teacher-" + suffix + "@example.com", "", Role.ADMIN, null);
        UserPrincipal student = new UserPrincipal(studentAuth.userId(), "student-" + suffix + "@example.com", "", Role.STUDENT, "REG-" + suffix);
        var createdClass = classService.create(new CreateClassRequest("CSE", "2026", "CSE101"), teacher);
        rosterService.addRoster(createdClass.id(), new RosterRequest(List.of("REG-" + suffix)), teacher);
        enrollmentService.join(new JoinClassRequest(createdClass.code(), "REG-" + suffix), student);
        var session = sessionLifecycleService.start(new StartSessionRequest(createdClass.id(), 2, 5), teacher);
        return new Fixture(student, session);
    }

    private String activePayload(Fixture fixture) {
        Awaitility.await().atMost(Duration.ofSeconds(3))
                .until(() -> sessionEngine.currentPayload(fixture.session().sessionId()).isPresent());
        return sessionEngine.currentPayload(fixture.session().sessionId()).orElseThrow();
    }

    private record Fixture(UserPrincipal student, com.jarvisatt.attendance.dto.SessionDtos.SessionResponse session) {}
}
