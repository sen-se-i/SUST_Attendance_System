package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.*;
import com.jarvisatt.attendance.dto.AuthDtos.*;
import com.jarvisatt.attendance.dto.ClassDtos.*;
import com.jarvisatt.attendance.exception.ApiException;
import com.jarvisatt.attendance.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminService {
    private final UserRepository userRepository;
    private final ClassRepository classRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final ClassSessionRepository classSessionRepository;
    private final DeviceRepository deviceRepository;
    private final PasswordEncoder passwordEncoder;
    private final ClassService classService;

    public static String deriveAcademicSession(String regNo) {
        if (regNo == null || regNo.trim().length() < 4) return "2023-24";
        String clean = regNo.trim();
        try {
            int year = Integer.parseInt(clean.substring(0, 4));
            int nextYearShort = (year + 1) % 100;
            return String.format("%04d-%02d", year, nextYearShort);
        } catch (Exception e) {
            return "2023-24";
        }
    }

    public static String deriveDepartment(String regNo) {
        if (regNo == null || regNo.trim().length() < 7) return "Software Engineering";
        String clean = regNo.trim();
        String code = clean.substring(4, 7);
        return switch (code) {
            case "831" -> "Software Engineering";
            case "331" -> "Computer Science and Engineering";
            case "332" -> "Electrical and Electronic Engineering";
            case "134" -> "Civil and Environmental Engineering";
            case "334" -> "Chemical Engineering and Polymer Science";
            case "333" -> "Industrial and Production Engineering";
            default -> "Software Engineering";
        };
    }

    @Transactional
    public UserSummaryResponse createStudent(CreateStudentRequest request) {
        String regNo = request.registrationNo().trim();
        if (userRepository.existsByRegistrationNo(regNo)) {
            throw new ApiException(HttpStatus.CONFLICT, "Student with registration number " + regNo + " already exists");
        }

        String dept = deriveDepartment(regNo);
        String session = deriveAcademicSession(regNo);

        User student = new User();
        student.setRole(Role.STUDENT);
        student.setRegistrationNo(regNo);
        student.setEmail(null); // Students do not require email
        student.setDepartment(dept);
        student.setAcademicSession(session);
        student.setPasswordHash(passwordEncoder.encode(request.password().trim()));

        userRepository.save(student);
        log.info("Admin created student: reg={}, dept={}, session={}", regNo, dept, session);

        // Auto-enroll new student into any active classes of this dept & session
        List<ClassEntity> activeClasses = classRepository.findByStatus("ACTIVE");
        for (ClassEntity cls : activeClasses) {
            if (dept.equalsIgnoreCase(cls.getDepartment()) && session.equalsIgnoreCase(cls.getAcademicSession())) {
                if (!enrollmentRepository.existsByClassEntityIdAndStudentIdAndStatus(cls.getId(), student.getId(), EnrollmentStatus.ACTIVE)) {
                    Enrollment enrollment = new Enrollment();
                    enrollment.setClassEntity(cls);
                    enrollment.setStudent(student);
                    enrollment.setStatus(EnrollmentStatus.ACTIVE);
                    enrollmentRepository.save(enrollment);
                    log.info("Auto-enrolled student {} into active class {}", regNo, cls.getCode());
                }
            }
        }

        return toUserSummary(student);
    }

    @Transactional
    public UserSummaryResponse createTeacher(CreateTeacherRequest request) {
        String email = request.email().trim().toLowerCase();
        if (userRepository.existsByEmail(email)) {
            throw new ApiException(HttpStatus.CONFLICT, "Teacher with email " + email + " already exists");
        }

        User teacher = new User();
        teacher.setRole(Role.TEACHER);
        teacher.setEmail(email);
        teacher.setDepartment(request.department().trim());
        teacher.setPasswordHash(passwordEncoder.encode(request.password().trim()));

        userRepository.save(teacher);
        log.info("Admin created teacher: email={}, dept={}", email, request.department());
        return toUserSummary(teacher);
    }

    @Transactional(readOnly = true)
    public List<UserSummaryResponse> listTeachers(String department) {
        List<User> teachers;
        if (department != null && !department.isBlank()) {
            teachers = userRepository.findByRoleAndDepartment(Role.TEACHER, department.trim());
        } else {
            teachers = userRepository.findByRole(Role.TEACHER);
        }
        return teachers.stream().map(this::toUserSummary).toList();
    }

    @Transactional(readOnly = true)
    public List<UserSummaryResponse> listStudents(String department, String academicSession) {
        List<User> students = userRepository.findByRole(Role.STUDENT);
        return students.stream()
                .filter(s -> department == null || department.isBlank() || department.equalsIgnoreCase(s.getDepartment()))
                .filter(s -> academicSession == null || academicSession.isBlank() || academicSession.equalsIgnoreCase(s.getAcademicSession()))
                .map(this::toUserSummary)
                .toList();
    }

    @Transactional
    public ClassResponse createClass(CreateClassRequest request) {
        if (request.academicSession() == null || !request.academicSession().matches("^\\d{4}-\\d{2}$")) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Session must be in format YYYY-YY (e.g. 2023-24)");
        }

        User teacher = null;
        if (request.teacherId() != null) {
            teacher = userRepository.findById(request.teacherId())
                    .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Selected teacher not found"));
        } else {
            List<User> deptTeachers = userRepository.findByRoleAndDepartment(Role.TEACHER, request.department());
            if (!deptTeachers.isEmpty()) {
                teacher = deptTeachers.get(0);
            } else {
                List<User> allTeachers = userRepository.findByRole(Role.TEACHER);
                if (!allTeachers.isEmpty()) {
                    teacher = allTeachers.get(0);
                } else {
                    throw new ApiException(HttpStatus.BAD_REQUEST, "No teacher available to assign to this class. Please create a teacher first.");
                }
            }
        }

        ClassEntity entity = new ClassEntity();
        entity.setCode(classService.generateClassCode(request.department(), request.academicSession(), request.semester(), request.subjectCode()));
        entity.setDepartment(request.department());
        entity.setAcademicSession(request.academicSession());
        entity.setSemester(request.semester());
        entity.setSubjectCode(request.subjectCode());
        entity.setSubjectName(request.subjectName());
        entity.setCredits(request.credits());
        entity.setTeacher(teacher);
        entity.setStatus("ACTIVE");
        classRepository.save(entity);

        // Auto-Enroll all matching students in this department and session
        List<User> allStudents = userRepository.findByRole(Role.STUDENT);
        int enrolledCount = 0;
        for (User st : allStudents) {
            String stDept = st.getDepartment() != null ? st.getDepartment() : deriveDepartment(st.getRegistrationNo());
            String stSession = st.getAcademicSession() != null ? st.getAcademicSession() : deriveAcademicSession(st.getRegistrationNo());

            if (request.department().equalsIgnoreCase(stDept) && request.academicSession().equalsIgnoreCase(stSession)) {
                if (!enrollmentRepository.existsByClassEntityIdAndStudentIdAndStatus(entity.getId(), st.getId(), EnrollmentStatus.ACTIVE)) {
                    Enrollment enrollment = new Enrollment();
                    enrollment.setClassEntity(entity);
                    enrollment.setStudent(st);
                    enrollment.setStatus(EnrollmentStatus.ACTIVE);
                    enrollmentRepository.save(enrollment);
                    enrolledCount++;
                }
            }
        }

        log.info("Created class {} and auto-enrolled {} students", entity.getCode(), enrolledCount);
        return classService.toClassResponse(entity);
    }

    @Transactional
    public void endClass(UUID classId) {
        ClassEntity cls = classRepository.findById(classId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Class not found"));
        cls.setStatus("ENDED");
        classRepository.save(cls);
        log.info("Admin ended class {}", cls.getCode());
    }

    @Transactional
    public void resetUserPassword(AdminResetPasswordRequest request) {
        String target = request.identifier().trim();
        User user = userRepository.findByRegistrationNo(target)
                .or(() -> userRepository.findByEmail(target.toLowerCase()))
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found for identifier: " + target));

        user.setPasswordHash(passwordEncoder.encode(request.newPassword().trim()));
        userRepository.save(user);
        deviceRepository.deleteByStudentId(user.getId());
        log.info("Admin reset password for user: {}", target);
    }

    private UserSummaryResponse toUserSummary(User u) {
        return new UserSummaryResponse(
                u.getId(),
                u.getEmail(),
                u.getRole(),
                u.getRegistrationNo(),
                u.getDepartment() != null ? u.getDepartment() : (u.getRole() == Role.STUDENT ? deriveDepartment(u.getRegistrationNo()) : null),
                u.getAcademicSession() != null ? u.getAcademicSession() : (u.getRole() == Role.STUDENT ? deriveAcademicSession(u.getRegistrationNo()) : null)
        );
    }
}
