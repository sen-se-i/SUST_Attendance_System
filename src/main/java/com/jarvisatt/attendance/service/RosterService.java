package com.jarvisatt.attendance.service;

import com.jarvisatt.attendance.domain.ClassRosterEntry;
import com.jarvisatt.attendance.dto.ClassDtos.RosterRequest;
import com.jarvisatt.attendance.repository.ClassRosterRepository;
import com.jarvisatt.attendance.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashSet;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RosterService {
    private final ClassService classService;
    private final ClassRosterRepository rosterRepository;

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
}
