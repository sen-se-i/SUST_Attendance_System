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
        entity.setCode(uniqueCode(request.subjectCode(), request.academicSession()));
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

    private String uniqueCode(String subjectCode, String academicSession) {
        if (subjectCode == null || subjectCode.isBlank()) {
            return "CLASS" + (System.currentTimeMillis() % 10000);
        }
        String cleanSubject = subjectCode.trim();
        if (cleanSubject.length() > 25) {
            cleanSubject = cleanSubject.substring(0, 25);
        }
        if (!classRepository.existsByCode(cleanSubject)) {
            return cleanSubject;
        }
        String cleanAlpha = cleanSubject.replaceAll("[^A-Za-z0-9]", "").toUpperCase();
        if (cleanAlpha.length() > 25) {
            cleanAlpha = cleanAlpha.substring(0, 25);
        }
        if (!classRepository.existsByCode(cleanAlpha)) {
            return cleanAlpha;
        }
        int counter = 1;
        String candidate;
        do {
            candidate = cleanAlpha + counter;
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
