package com.jarvisatt.attendance.config;

import com.jarvisatt.attendance.domain.*;
import com.jarvisatt.attendance.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final ClassRepository classRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) {
        log.info("Initializing demo seed data...");

        // 1. Seed Admin
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

        // 2. Seed Teacher
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

        // 3. Seed 60 Students (2023831001 to 2023831060)
        List<User> students = new ArrayList<>();
        String encodedDefaultPass = passwordEncoder.encode("password"); // baseline fallback

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
            student.setEmail(null); // No email necessary for students
            student.setDepartment("Software Engineering");
            student.setAcademicSession("2023-24");
            // Student password is their own registration number
            student.setPasswordHash(passwordEncoder.encode(currentReg));
            student = userRepository.save(student);
            students.add(student);
        }
        log.info("Seeded/verified 60 students (2023831001 to 2023831060)");

        // 4. Seed Demo Class
        String classCode = "SWE2324-11-301";
        final User finalTeacher = teacher;
        ClassEntity demoClass = classRepository.findByCode(classCode)
                .or(() -> classRepository.findByCode("SWE301"))
                .orElseGet(() -> {
                    ClassEntity c = new ClassEntity();
                    c.setCode(classCode);
                    c.setDepartment("Software Engineering");
                    c.setAcademicSession("2023-24");
                    c.setSemester("1st Year 1st Semester");
                    c.setSubjectCode("SWE-301");
                    c.setSubjectName("Software Engineering");
                    c.setCredits(3.0);
                    c.setTeacher(finalTeacher);
                    c.setStatus("ACTIVE");
                    return classRepository.save(c);
                });

        demoClass.setCode(classCode);
        demoClass.setDepartment("Software Engineering");
        demoClass.setAcademicSession("2023-24");
        demoClass.setSemester("1st Year 1st Semester");
        demoClass.setSubjectCode("SWE-301");
        demoClass.setSubjectName("Software Engineering");
        demoClass.setCredits(3.0);
        demoClass.setTeacher(teacher);
        demoClass.setStatus("ACTIVE");
        demoClass = classRepository.save(demoClass);

        // 5. Enroll all 60 students in the demo class
        for (User st : students) {
            if (!enrollmentRepository.existsByClassEntityIdAndStudentIdAndStatus(demoClass.getId(), st.getId(), EnrollmentStatus.ACTIVE)) {
                Enrollment enrollment = new Enrollment();
                enrollment.setClassEntity(demoClass);
                enrollment.setStudent(st);
                enrollment.setStatus(EnrollmentStatus.ACTIVE);
                enrollmentRepository.save(enrollment);
            }
        }

        log.info("Demo seed data initialization complete. Enrolled 60 students in {}", demoClass.getCode());
    }
}
