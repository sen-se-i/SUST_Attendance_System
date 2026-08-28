package com.jarvisatt.attendance.repository;

import com.jarvisatt.attendance.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    Optional<User> findByRegistrationNo(String registrationNo);
    boolean existsByEmail(String email);
    boolean existsByRegistrationNo(String registrationNo);
    java.util.List<User> findByRole(com.jarvisatt.attendance.domain.Role role);
    java.util.List<User> findByRoleAndDepartment(com.jarvisatt.attendance.domain.Role role, String department);
    java.util.List<User> findByRoleAndDepartmentAndAcademicSession(com.jarvisatt.attendance.domain.Role role, String department, String academicSession);
}

