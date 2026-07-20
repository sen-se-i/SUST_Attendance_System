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

@Service
@RequiredArgsConstructor
public class EnrollmentService {
    private final ClassRepository classRepository;
    private final ClassRosterRepository rosterRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final UserRepository userRepository;

    @Transactional
    public JoinClassResponse join(JoinClassRequest request, UserPrincipal studentPrincipal) {
        User student = userRepository.findById(studentPrincipal.id()).orElseThrow();
        if (!request.registrationNo().equals(student.getRegistrationNo())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Registration number does not match logged-in student");
        }
        ClassEntity classEntity = classRepository.findByCode(request.classCode())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Class code not found"));
        if (!rosterRepository.existsByClassIdAndRegistrationNo(classEntity.getId(), request.registrationNo())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Registration number is not in this class roster");
        }
        Enrollment enrollment = enrollmentRepository.findByClassEntityIdAndStudentId(classEntity.getId(), student.getId())
                .orElseGet(Enrollment::new);
        enrollment.setClassEntity(classEntity);
        enrollment.setStudent(student);
        enrollment.setStatus(EnrollmentStatus.ACTIVE);
        enrollmentRepository.save(enrollment);
        return new JoinClassResponse(enrollment.getId(), classEntity.getId(), enrollment.getStatus().name());
    }
}
