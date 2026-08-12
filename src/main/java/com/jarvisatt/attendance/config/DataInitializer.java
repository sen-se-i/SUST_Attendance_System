package com.jarvisatt.attendance.config;

import com.jarvisatt.attendance.domain.*;
import com.jarvisatt.attendance.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final ClassRepository classRepository;
    private final ClassRosterRepository classRosterRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) {
        log.info("Initializing demo seed data...");

        // 1. Seed Teacher
        User teacher = userRepository.findByEmail("teacher@example.com")
                .orElseGet(() -> {
                    User u = new User();
                    u.setEmail("teacher@example.com");
                    u.setPasswordHash(passwordEncoder.encode("password"));
                    u.setRole(Role.ADMIN);
                    return userRepository.save(u);
                });

        // 2. Seed Student (ch.wixard@student.sust.edu)
        User student = userRepository.findByEmail("ch.wixard@student.sust.edu")
                .orElseGet(() -> {
                    User u = new User();
                    u.setEmail("ch.wixard@student.sust.edu");
                    u.setPasswordHash(passwordEncoder.encode("password"));
                    u.setRole(Role.STUDENT);
                    u.setRegistrationNo("2023831001");
                    return userRepository.save(u);
                });

        // Ensure student registration number is set
        if (student.getRegistrationNo() == null || student.getRegistrationNo().isBlank()) {
            student.setRegistrationNo("2023831001");
            userRepository.save(student);
        }

        // 3. Seed Demo Class if teacher has no classes
        List<ClassEntity> teacherClasses = classRepository.findByTeacherId(teacher.getId());
        ClassEntity demoClass;
        if (teacherClasses.isEmpty()) {
            demoClass = new ClassEntity();
            demoClass.setCode("SWE301");
            demoClass.setDepartment("Software Engineering");
            demoClass.setAcademicSession("2023-2024");
            demoClass.setSubjectCode("SWE-301");
            demoClass.setTeacher(teacher);
            demoClass = classRepository.save(demoClass);
            log.info("Created demo class SWE301 with ID {}", demoClass.getId());
        } else {
            demoClass = teacherClasses.get(0);
        }

        // 4. Add student to roster for demo class
        if (!classRosterRepository.existsByClassIdAndRegistrationNo(demoClass.getId(), student.getRegistrationNo())) {
            classRosterRepository.save(new ClassRosterEntry(demoClass.getId(), student.getRegistrationNo()));
            log.info("Added student registration {} to class roster {}", student.getRegistrationNo(), demoClass.getCode());
        }

        // 5. Enroll student in demo class
        if (!enrollmentRepository.existsByClassEntityIdAndStudentIdAndStatus(demoClass.getId(), student.getId(), EnrollmentStatus.ACTIVE)) {
            Enrollment enrollment = new Enrollment();
            enrollment.setClassEntity(demoClass);
            enrollment.setStudent(student);
            enrollment.setStatus(EnrollmentStatus.ACTIVE);
            enrollmentRepository.save(enrollment);
            log.info("Enrolled student {} in demo class {}", student.getEmail(), demoClass.getCode());
        }

        log.info("Demo seed data initialization complete.");
    }
}
