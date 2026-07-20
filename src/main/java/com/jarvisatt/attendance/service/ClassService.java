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
        ClassEntity entity = new ClassEntity();
        entity.setCode(uniqueCode());
        entity.setDepartment(request.department());
        entity.setAcademicSession(request.academicSession());
        entity.setSubjectCode(request.subjectCode());
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

    private String uniqueCode() {
        String code;
        do {
            StringBuilder builder = new StringBuilder(6);
            for (int i = 0; i < 6; i++) {
                builder.append(ALPHABET.charAt(random.nextInt(ALPHABET.length())));
            }
            code = builder.toString();
        } while (classRepository.existsByCode(code));
        return code;
    }

    private ClassResponse response(ClassEntity entity) {
        return new ClassResponse(entity.getId(), entity.getCode(), entity.getDepartment(), entity.getAcademicSession(), entity.getSubjectCode());
    }
}
