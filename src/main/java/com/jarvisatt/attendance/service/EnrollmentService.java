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
    public JoinClassResponse joinDirect(JoinClassDirectRequest request, UserPrincipal studentPrincipal) {
        User student = userRepository.findById(studentPrincipal.id()).orElseThrow();
        
        String inputCode = request.effectiveCode();
        String normalizedCode = inputCode.replaceAll("[^A-Za-z0-9]", "").toUpperCase();

        ClassEntity classEntity = classRepository.findByCode(inputCode)
                .or(() -> classRepository.findFirstByCodeIgnoreCase(inputCode))
                .or(() -> classRepository.findFirstByCodeIgnoreCase(normalizedCode))
                .or(() -> classRepository.findFirstBySubjectCodeIgnoreCase(inputCode))
                .or(() -> classRepository.findFirstBySubjectCodeIgnoreCase(normalizedCode))
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Class or Subject code '" + inputCode + "' not found. Please check with your teacher."));

        Enrollment enrollment = enrollmentRepository.findByClassEntityIdAndStudentId(classEntity.getId(), student.getId())
                .orElseGet(Enrollment::new);
        enrollment.setClassEntity(classEntity);
        enrollment.setStudent(student);
        enrollment.setStatus(EnrollmentStatus.ACTIVE);
        enrollmentRepository.save(enrollment);
        return new JoinClassResponse(enrollment.getId(), classEntity.getId(), enrollment.getStatus().name());
    }

    public java.util.List<EnrolledStudentResponse> getEnrolledStudents(java.util.UUID classId) {
        return enrollmentRepository.findByClassEntityIdAndStatus(classId, EnrollmentStatus.ACTIVE)
                .stream()
                .map(e -> new EnrolledStudentResponse(
                        e.getStudent().getRegistrationNo(),
                        e.getStudent().getEmail(),
                        e.getStatus().name(),
                        e.getJoinedAt()
                ))
                .toList();
    }
}
