package com.jarvisatt.attendance.repository;

import com.jarvisatt.attendance.domain.ClassEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ClassRepository extends JpaRepository<ClassEntity, UUID> {
    boolean existsByCode(String code);
    Optional<ClassEntity> findByCode(String code);
    List<ClassEntity> findByTeacherId(UUID teacherId);
}
