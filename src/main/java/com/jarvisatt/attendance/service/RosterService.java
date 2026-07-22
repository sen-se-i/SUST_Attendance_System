package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.ClassRosterEntry;
import com.jarvisatt.attendance.domain.EnrollmentStatus;
import com.jarvisatt.attendance.dto.ClassDtos.RosterEntryResponse;
import com.jarvisatt.attendance.dto.ClassDtos.RosterRequest;
import com.jarvisatt.attendance.repository.ClassRosterRepository;
import com.jarvisatt.attendance.repository.EnrollmentRepository;
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
                .collect(Collectors.toSet());
        return rosterRepository.findByClassIdOrderByRegistrationNo(classId).stream()
                .map(entry -> new RosterEntryResponse(entry.getRegistrationNo(), joinedRegistrationNos.contains(entry.getRegistrationNo())))
                .toList();
    }
}
