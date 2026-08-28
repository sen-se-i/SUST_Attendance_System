package com.jarvisatt.attendance.repository;

import com.jarvisatt.attendance.domain.ClassEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ClassRepository extends JpaRepository<ClassEntity, UUID> {
    boolean existsByCode(String code);
    Optional<ClassEntity> findByCode(String code);
    Optional<ClassEntity> findFirstByCodeIgnoreCase(String code);
    Optional<ClassEntity> findFirstBySubjectCodeIgnoreCase(String subjectCode);
    List<ClassEntity> findByTeacherId(UUID teacherId);
    List<ClassEntity> findByTeacherIdAndStatus(UUID teacherId, String status);
    List<ClassEntity> findByStatus(String status);
    List<ClassEntity> findAllByOrderByCreatedAtDesc();
    boolean existsByTeacherIdAndAcademicSessionAndSemesterAndSubjectCode(UUID teacherId, String academicSession, String semester, String subjectCode);
}

