package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.ClassEntity;
import com.jarvisatt.attendance.domain.User;
import com.jarvisatt.attendance.dto.ClassDtos.*;
import com.jarvisatt.attendance.exception.ApiException;
import com.jarvisatt.attendance.repository.ClassRepository;
import com.jarvisatt.attendance.repository.UserRepository;
import com.jarvisatt.attendance.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ClassService {
    private static final String ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private final SecureRandom random = new SecureRandom();
    private final ClassRepository classRepository;
    private final UserRepository userRepository;
    private final com.jarvisatt.attendance.repository.EnrollmentRepository enrollmentRepository;

    @Transactional(readOnly = true)
    public List<ClassResponse> studentClasses(UserPrincipal student) {
        return enrollmentRepository.findByStudentIdAndStatus(student.id(), com.jarvisatt.attendance.domain.EnrollmentStatus.ACTIVE).stream()
                .map(enrollment -> response(enrollment.getClassEntity()))
                .toList();
    }

    @Transactional
    public ClassResponse create(CreateClassRequest request, UserPrincipal teacher) {
        User owner = userRepository.findById(teacher.id()).orElseThrow();

        // 1. Session format validation (YYYY-YY e.g. 2023-24)
        if (request.academicSession() == null || !request.academicSession().matches("^\\d{4}-\\d{2}$")) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Session must be in format YYYY-YY (e.g. 2023-24)");
        }

        // 2. Duplicate Subject check for Session + Semester + Subject
        if (classRepository.existsByTeacherIdAndAcademicSessionAndSemesterAndSubjectCode(
                teacher.id(), request.academicSession(), request.semester(), request.subjectCode())) {
            throw new ApiException(HttpStatus.CONFLICT, 
                "Class already exists for subject " + request.subjectCode() + " in session " + request.academicSession() + " (" + request.semester() + ")");
        }

        ClassEntity entity = new ClassEntity();
        entity.setCode(generateClassCode(request.department(), request.academicSession(), request.semester(), request.subjectCode()));
        entity.setDepartment(request.department());
        entity.setAcademicSession(request.academicSession());
        entity.setSemester(request.semester());
        entity.setSubjectCode(request.subjectCode());
        entity.setSubjectName(request.subjectName());
        entity.setCredits(request.credits());
        entity.setTeacher(owner);
        classRepository.save(entity);
        return response(entity);
    }

    @Transactional(readOnly = true)
    public ClassEntity ownedClass(java.util.UUID classId, UserPrincipal teacher) {
        ClassEntity entity = classRepository.findById(classId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Class not found"));
        if (!entity.getTeacher().getId().equals(teacher.id())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not own this class");
        }
        return entity;
    }

    @Transactional(readOnly = true)
    public List<ClassResponse> teacherClasses(UserPrincipal teacher) {
        return classRepository.findByTeacherId(teacher.id()).stream().map(this::response).toList();
    }

    /**
     * Generates a human-readable, structured class code:
     * Format: <DEPT><SESSION>-<YEAR_SEM>-<COURSE_NUM>
     * Example 1: Software Engineering, 2024-25, Year 1 Semester 2, EEE0712-1102W -> SWE2425-12-1102W
     * Example 2: Software Engineering, 2023-24, Year 4 Semester 2, SWE0613-4125  -> SWE2324-42-4125
     */
    private String generateClassCode(String department, String academicSession, String semester, String subjectCode) {
        // 1. Department code
        String deptPrefix = "SWE";
        if (department != null) {
            String cleanDept = department.trim().toUpperCase();
            if (cleanDept.contains("SOFTWARE")) {
                deptPrefix = "SWE";
            } else if (cleanDept.contains("COMPUTER") || cleanDept.contains("CSE")) {
                deptPrefix = "CSE";
            } else if (cleanDept.contains("ELECTRICAL") || cleanDept.contains("EEE")) {
                deptPrefix = "EEE";
            } else {
                String[] words = cleanDept.split("\\s+");
                StringBuilder sb = new StringBuilder();
                for (String w : words) {
                    if (!w.isBlank()) sb.append(w.charAt(0));
                }
                deptPrefix = sb.length() > 0 ? sb.toString() : "CLASS";
            }
        }

        // 2. Session code (e.g. "2024-25" -> "2425", "2023-24" -> "2324")
        String sessionPart = "2425";
        if (academicSession != null) {
            String digits = academicSession.replaceAll("\\D", "");
            if (digits.length() == 6) { // e.g. 202425
                sessionPart = digits.substring(2, 4) + digits.substring(4, 6); // "24" + "25" -> "2425"
            } else if (digits.length() == 8) { // e.g. 20242025
                sessionPart = digits.substring(2, 4) + digits.substring(6, 8); // "24" + "25" -> "2425"
            } else if (digits.length() >= 4) {
                sessionPart = digits.substring(digits.length() - 4);
            } else if (!digits.isEmpty()) {
                sessionPart = digits;
            }
        }

        // 3. Year & Semester code (e.g. "Year 1 Semester 2" -> "12", "Year 4 Semester 2" -> "42")
        String semPart = "11";
        if (semester != null) {
            String digits = semester.replaceAll("\\D", "");
            if (digits.length() >= 2) {
                semPart = digits.substring(0, 2);
            } else if (digits.length() == 1) {
                semPart = digits;
            }
        }

        // 4. Course number from subject code (e.g. "EEE0712-1102W" -> "1102W", "SWE0613-4125" -> "4125")
        String coursePart = "0000";
        if (subjectCode != null && !subjectCode.isBlank()) {
            String cleanSubject = subjectCode.trim();
            if (cleanSubject.contains("-")) {
                coursePart = cleanSubject.substring(cleanSubject.lastIndexOf('-') + 1).trim();
            } else {
                coursePart = cleanSubject.replaceAll("[^A-Za-z0-9]", "");
            }
        }

        // Base code: e.g. SWE2425-12-1102W
        String baseCode = deptPrefix + sessionPart + "-" + semPart + "-" + coursePart;
        if (baseCode.length() > 28) {
            baseCode = baseCode.substring(0, 28);
        }

        if (!classRepository.existsByCode(baseCode)) {
            return baseCode;
        }

        int counter = 1;
        String candidate;
        do {
            candidate = baseCode + "-" + counter;
            if (candidate.length() > 30) {
                candidate = baseCode.substring(0, 27) + "-" + counter;
            }
            counter++;
        } while (classRepository.existsByCode(candidate));
        return candidate;
    }

    private final com.jarvisatt.attendance.repository.ClassSessionRepository classSessionRepository;

    private ClassResponse response(ClassEntity entity) {
        String teacherName = entity.getTeacher() != null ? entity.getTeacher().getEmail() : "Faculty";
        java.time.OffsetDateTime lastSessionAt = classSessionRepository
                .findFirstByClassEntityIdOrderByStartedAtDesc(entity.getId())
                .map(com.jarvisatt.attendance.domain.ClassSession::getStartedAt)
                .orElse(null);

        return new ClassResponse(
            entity.getId(),
            entity.getCode(),
            entity.getDepartment(),
            entity.getAcademicSession(),
            entity.getSemester(),
            entity.getSubjectCode(),
            entity.getSubjectName(),
            entity.getCredits(),
            teacherName,
            lastSessionAt
        );
    }
}
