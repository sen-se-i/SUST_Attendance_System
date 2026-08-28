package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.*;
import com.jarvisatt.attendance.dto.ClassDtos.*;
import com.jarvisatt.attendance.exception.ApiException;
import com.jarvisatt.attendance.repository.*;
import com.jarvisatt.attendance.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class ClassStudentService {
    private final ClassService classService;
    private final EnrollmentRepository enrollmentRepository;
    private final AttendanceRecordRepository attendanceRecordRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<ClassStudentResponse> listStudents(UUID classId, UserPrincipal principal) {
        classService.ownedClass(classId, principal);
        return enrollmentRepository.findByClassEntityIdAndStatus(classId, EnrollmentStatus.ACTIVE).stream()
                .map(e -> new ClassStudentResponse(
                        e.getStudent().getRegistrationNo(),
                        e.getStudent().getEmail(),
                        e.getStatus().name(),
                        e.getJoinedAt()
                ))
                .sorted(Comparator.comparing(ClassStudentResponse::registrationNo, Comparator.nullsLast(String::compareTo)))
                .toList();
    }

    @Transactional
    public void addStudent(UUID classId, String registrationNo, UserPrincipal principal) {
        ClassEntity classEntity = classService.ownedClass(classId, principal);
        String reg = registrationNo.trim();
        User student = userRepository.findByRegistrationNo(reg)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Student with registration number " + reg + " not found"));

        if (!enrollmentRepository.existsByClassEntityIdAndStudentIdAndStatus(classId, student.getId(), EnrollmentStatus.ACTIVE)) {
            Enrollment enrollment = new Enrollment();
            enrollment.setClassEntity(classEntity);
            enrollment.setStudent(student);
            enrollment.setStatus(EnrollmentStatus.ACTIVE);
            enrollmentRepository.save(enrollment);
            log.info("Student {} added to class {} by {}", reg, classEntity.getCode(), principal.getUsername());
        }
    }

    @Transactional
    public void removeStudent(UUID classId, String registrationNo, UserPrincipal principal) {
        ClassEntity classEntity = classService.ownedClass(classId, principal);
        String reg = registrationNo.trim();
        userRepository.findByRegistrationNo(reg).ifPresent(student -> {
            enrollmentRepository.deleteByClassEntityIdAndStudentId(classId, student.getId());
            attendanceRecordRepository.deleteByClassEntityIdAndStudentId(classId, student.getId());
            log.info("Student {} and attendance history removed from class {} by {}", reg, classEntity.getCode(), principal.getUsername());
        });
    }
}
