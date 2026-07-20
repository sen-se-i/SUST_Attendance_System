package com.jarvisatt.attendance.repository;

import com.jarvisatt.attendance.domain.ClassRosterEntry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ClassRosterRepository extends JpaRepository<ClassRosterEntry, ClassRosterEntry.RosterId> {
    boolean existsByClassIdAndRegistrationNo(UUID classId, String registrationNo);
}
