package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.ClassRosterEntry;
import com.jarvisatt.attendance.domain.EnrollmentStatus;
import com.jarvisatt.attendance.dto.ClassDtos.RosterEntryResponse;
import com.jarvisatt.attendance.dto.ClassDtos.RosterRequest;
import com.jarvisatt.attendance.repository.AttendanceRecordRepository;
import com.jarvisatt.attendance.repository.ClassRosterRepository;
import com.jarvisatt.attendance.repository.EnrollmentRepository;
import com.jarvisatt.attendance.repository.UserRepository;
import com.jarvisatt.attendance.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RosterService {
    private final ClassService classService;
    private final ClassRosterRepository rosterRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final AttendanceRecordRepository attendanceRecordRepository;
    private final UserRepository userRepository;

    @Transactional
    public int addRoster(UUID classId, RosterRequest request, UserPrincipal teacher) {
        classService.ownedClass(classId, teacher);
        var unique = new LinkedHashSet<>(request.registrationNos());
        unique.forEach(reg -> {
            String normalized = reg.trim();
            if (!rosterRepository.existsByClassIdAndRegistrationNo(classId, normalized)) {
                rosterRepository.save(new ClassRosterEntry(classId, normalized));
            }
        });
        return unique.size();
    }

    @Transactional(readOnly = true)
    public java.util.List<RosterEntryResponse> listRoster(UUID classId, UserPrincipal teacher) {
        classService.ownedClass(classId, teacher);
        Set<String> joinedRegistrationNos = enrollmentRepository.findByClassEntityIdAndStatus(classId, EnrollmentStatus.ACTIVE).stream()
                .map(enrollment -> enrollment.getStudent().getRegistrationNo())
                .filter(java.util.Objects::nonNull)
                .collect(Collectors.toSet());

        Set<String> allRegs = new java.util.LinkedHashSet<>(joinedRegistrationNos);
        rosterRepository.findByClassIdOrderByRegistrationNo(classId).forEach(entry -> allRegs.add(entry.getRegistrationNo()));

        return allRegs.stream()
                .map(reg -> new RosterEntryResponse(reg, joinedRegistrationNos.contains(reg)))
                .toList();
    }

    /** Removes a student from the class roster, enrollment, and purges their attendance records for this class. */
    @Transactional
    public void removeStudentFromClass(UUID classId, String registrationNo, UserPrincipal teacher) {
        classService.ownedClass(classId, teacher);
        String normalized = registrationNo.trim();
        rosterRepository.deleteByClassIdAndRegistrationNo(classId, normalized);
        userRepository.findByRegistrationNo(normalized).ifPresent(student -> {
            enrollmentRepository.deleteByClassEntityIdAndStudentId(classId, student.getId());
            attendanceRecordRepository.deleteByClassEntityIdAndStudentId(classId, student.getId());
        });
    }
}
