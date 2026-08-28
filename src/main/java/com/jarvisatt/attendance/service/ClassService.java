package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.*;
import com.jarvisatt.attendance.dto.ClassDtos.*;
import com.jarvisatt.attendance.exception.ApiException;
import com.jarvisatt.attendance.repository.*;
import com.jarvisatt.attendance.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ClassService {
    private final ClassRepository classRepository;
    private final UserRepository userRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final ClassSessionRepository classSessionRepository;

    @Transactional(readOnly = true)
    public List<ClassResponse> studentClasses(UserPrincipal student) {
        return enrollmentRepository.findByStudentIdAndStatus(student.id(), EnrollmentStatus.ACTIVE).stream()
                .map(Enrollment::getClassEntity)
                .filter(c -> c.getStatus() == null || "ACTIVE".equalsIgnoreCase(c.getStatus()))
                .map(this::toClassResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ClassResponse> teacherClasses(UserPrincipal teacher) {
        if (teacher.role() == Role.ADMIN) {
            return classRepository.findAllByOrderByCreatedAtDesc().stream()
                    .map(this::toClassResponse)
                    .toList();
        }
        return classRepository.findByTeacherId(teacher.id()).stream()
                .filter(c -> c.getStatus() == null || "ACTIVE".equalsIgnoreCase(c.getStatus()))
                .map(this::toClassResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ClassResponse> allClassesForAdmin() {
        return classRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(this::toClassResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public ClassEntity ownedClass(UUID classId, UserPrincipal principal) {
        ClassEntity entity = classRepository.findById(classId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Class not found"));
        if (principal.role() != Role.ADMIN) {
            if (entity.getTeacher() == null || !entity.getTeacher().getId().equals(principal.id())) {
                throw new ApiException(HttpStatus.FORBIDDEN, "You do not own this class");
            }
        }
        return entity;
    }

    public String generateClassCode(String department, String academicSession, String semester, String subjectCode) {
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

        String sessionPart = "2425";
        if (academicSession != null) {
            String digits = academicSession.replaceAll("\\D", "");
            if (digits.length() == 6) {
                sessionPart = digits.substring(2, 4) + digits.substring(4, 6);
            } else if (digits.length() == 8) {
                sessionPart = digits.substring(2, 4) + digits.substring(6, 8);
            } else if (digits.length() >= 4) {
                sessionPart = digits.substring(digits.length() - 4);
            } else if (!digits.isEmpty()) {
                sessionPart = digits;
            }
        }

        String semPart = "11";
        if (semester != null) {
            String digits = semester.replaceAll("\\D", "");
            if (digits.length() >= 2) {
                semPart = digits.substring(0, 2);
            } else if (digits.length() == 1) {
                semPart = digits;
            }
        }

        String coursePart = "0000";
        if (subjectCode != null && !subjectCode.isBlank()) {
            String cleanSubject = subjectCode.trim();
            if (cleanSubject.contains("-")) {
                coursePart = cleanSubject.substring(cleanSubject.lastIndexOf('-') + 1).trim();
            } else {
                coursePart = cleanSubject.replaceAll("[^A-Za-z0-9]", "");
            }
        }

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

    public ClassResponse toClassResponse(ClassEntity entity) {
        String teacherName = entity.getTeacher() != null ? entity.getTeacher().getEmail() : "Faculty";
        UUID teacherId = entity.getTeacher() != null ? entity.getTeacher().getId() : null;

        java.time.OffsetDateTime lastSessionAt = classSessionRepository
                .findFirstByClassEntityIdOrderByStartedAtDesc(entity.getId())
                .map(ClassSession::getStartedAt)
                .orElse(null);

        List<Enrollment> enrollments = enrollmentRepository.findByClassEntityIdAndStatus(entity.getId(), EnrollmentStatus.ACTIVE);
        int enrolledCount = enrollments.size();
        List<ClassSession> sessions = classSessionRepository.findByClassEntityIdOrderByStartedAtDesc(entity.getId());
        int totalSessions = sessions.size();

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
                teacherId,
                entity.getStatus() != null ? entity.getStatus() : "ACTIVE",
                enrolledCount,
                totalSessions,
                lastSessionAt
        );
    }
}
