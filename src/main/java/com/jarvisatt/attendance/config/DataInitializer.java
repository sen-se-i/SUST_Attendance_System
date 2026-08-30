package com.jarvisatt.attendance.config;

import com.jarvisatt.attendance.domain.*;
import com.jarvisatt.attendance.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final ClassRepository classRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final ClassSessionRepository classSessionRepository;
    private final AttendanceRecordRepository attendanceRecordRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) {
        log.info("Initializing demo seed data...");

        User admin = userRepository.findByEmail("admin@example.com")
                .orElseGet(() -> {
                    User u = new User();
                    u.setEmail("admin@example.com");
                    u.setRole(Role.ADMIN);
                    return u;
                });
        admin.setRole(Role.ADMIN);
        admin.setPasswordHash(passwordEncoder.encode("password"));
        userRepository.save(admin);

        User teacher = userRepository.findByEmail("teacher@example.com")
                .orElseGet(() -> {
                    User u = new User();
                    u.setEmail("teacher@example.com");
                    u.setRole(Role.TEACHER);
                    return u;
                });
        teacher.setRole(Role.TEACHER);
        teacher.setDepartment("Software Engineering");
        teacher.setPasswordHash(passwordEncoder.encode("password"));
        teacher = userRepository.save(teacher);

        List<User> students = new ArrayList<>();
        for (int i = 1; i <= 60; i++) {
            String regNo = String.format("2023831%03d", i);
            final String currentReg = regNo;
            User student = userRepository.findByRegistrationNo(currentReg)
                    .orElseGet(() -> {
                        User u = new User();
                        u.setRegistrationNo(currentReg);
                        u.setRole(Role.STUDENT);
                        return u;
                    });

            student.setRole(Role.STUDENT);
            student.setRegistrationNo(currentReg);
            student.setEmail(null);
            student.setDepartment("Software Engineering");
            student.setAcademicSession("2023-24");
            student.setPasswordHash(passwordEncoder.encode(currentReg));
            student = userRepository.save(student);
            students.add(student);
        }
        log.info("Seeded/verified 60 students");

        List<String> classCodes = List.of("SWE0541-2231", "SWE2324-11-301");
        final User finalTeacher = teacher;

        for (String code : classCodes) {
            ClassEntity demoClass = classRepository.findByCode(code)
                    .orElseGet(() -> {
                        ClassEntity c = new ClassEntity();
                        c.setCode(code);
                        c.setDepartment("Software Engineering");
                        c.setAcademicSession("2023-24");
                        c.setSemester("2nd Year 1st Semester");
                        c.setSubjectCode("SWE-223");
                        c.setSubjectName("Software Architecture & Design");
                        c.setCredits(3.0);
                        c.setTeacher(finalTeacher);
                        c.setStatus("ACTIVE");
                        return classRepository.save(c);
                    });

            demoClass.setDepartment("Software Engineering");
            demoClass.setTeacher(finalTeacher);
            demoClass.setStatus("ACTIVE");
            demoClass = classRepository.save(demoClass);

            for (User st : students) {
                if (!enrollmentRepository.existsByClassEntityIdAndStudentIdAndStatus(demoClass.getId(), st.getId(), EnrollmentStatus.ACTIVE)) {
                    Enrollment enrollment = new Enrollment();
                    enrollment.setClassEntity(demoClass);
                    enrollment.setStudent(st);
                    enrollment.setStatus(EnrollmentStatus.ACTIVE);
                    enrollmentRepository.save(enrollment);
                }
            }

            List<ClassSession> existingSessions = classSessionRepository.findByClassEntityIdOrderByStartedAtAsc(demoClass.getId());
            if (existingSessions.isEmpty()) {
                log.info("Seeding 15 attendance sessions and ~84% attendance matrix for class {}", code);
                Random random = new Random(42);
                OffsetDateTime baseDate = OffsetDateTime.of(2024, 10, 1, 10, 0, 0, 0, ZoneOffset.ofHours(6));

                List<ClassSession> newSessions = new ArrayList<>();
                for (int s = 0; s < 15; s++) {
                    OffsetDateTime sTime = baseDate.plusDays(s * 2L + (s % 3));
                    ClassSession session = new ClassSession();
                    session.setClassEntity(demoClass);
                    session.setStartedAt(sTime);
                    session.setEndedAt(sTime.plusMinutes(50));
                    session.setStatus(ClassSessionStatus.ENDED);
                    session.setTotalTicks(4);
                    session.setTickIntervalSeconds(3);
                    session.setLatitude(24.9006);
                    session.setLongitude(91.8695);
                    session.setRadiusMeters(50.0);
                    session = classSessionRepository.save(session);
                    newSessions.add(session);
                }

                for (int stIdx = 0; stIdx < students.size(); stIdx++) {
                    User st = students.get(stIdx);

                    double studentTargetPct;
                    int group = stIdx % 10;
                    if (group < 2) studentTargetPct = 0.98;
                    else if (group < 5) studentTargetPct = 0.90;
                    else if (group < 7) studentTargetPct = 0.84;
                    else if (group < 9) studentTargetPct = 0.72;
                    else studentTargetPct = 0.45;

                    for (ClassSession session : newSessions) {
                        if (random.nextDouble() <= studentTargetPct) {
                            AttendanceRecord rec = new AttendanceRecord();
                            rec.setSession(session);
                            rec.setClassEntity(demoClass);
                            rec.setRegistrationNo(st.getRegistrationNo());
                            rec.setStudent(st);
                            rec.setDeviceInstallId("DEMO_DEV_" + st.getRegistrationNo());
                            rec.setScannedAt(session.getStartedAt().plusMinutes(random.nextInt(15) + 1));
                            rec.setDistanceMeters(Math.round(random.nextDouble() * 35.0 * 10.0) / 10.0 + 2.0);
                            rec.setVerificationStatus("VERIFIED");
                            attendanceRecordRepository.save(rec);
                        }
                    }
                }
                log.info("Attendance seeding complete for class {}", code);
            }
        }

        log.info("Demo seed data initialization complete.");
    }
}

