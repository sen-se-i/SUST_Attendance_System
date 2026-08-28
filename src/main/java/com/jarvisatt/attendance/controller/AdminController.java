package com.jarvisatt.attendance.controller;

import com.jarvisatt.attendance.dto.AuthDtos.*;
import com.jarvisatt.attendance.dto.ClassDtos.*;
import com.jarvisatt.attendance.service.AdminService;
import com.jarvisatt.attendance.service.ClassService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminController {
    private final AdminService adminService;
    private final ClassService classService;

    @PostMapping("/students")
    public UserSummaryResponse createStudent(@Valid @RequestBody CreateStudentRequest request) {
        return adminService.createStudent(request);
    }

    @PostMapping("/teachers")
    public UserSummaryResponse createTeacher(@Valid @RequestBody CreateTeacherRequest request) {
        return adminService.createTeacher(request);
    }

    @GetMapping("/teachers")
    public List<UserSummaryResponse> listTeachers(@RequestParam(required = false) String department) {
        return adminService.listTeachers(department);
    }

    @GetMapping("/students")
    public List<UserSummaryResponse> listStudents(@RequestParam(required = false) String department,
                                                  @RequestParam(required = false) String academicSession) {
        return adminService.listStudents(department, academicSession);
    }

    @PostMapping("/classes")
    public ClassResponse createClass(@Valid @RequestBody CreateClassRequest request) {
        return adminService.createClass(request);
    }

    @GetMapping("/classes")
    public List<ClassResponse> listAllClasses() {
        return classService.allClassesForAdmin();
    }

    @PostMapping("/classes/{classId}/end")
    public Map<String, String> endClass(@PathVariable UUID classId) {
        adminService.endClass(classId);
        return Map.of("status", "ENDED", "classId", classId.toString());
    }

    @PostMapping("/users/reset-password")
    public Map<String, String> resetPassword(@Valid @RequestBody AdminResetPasswordRequest request) {
        adminService.resetUserPassword(request);
        return Map.of("status", "SUCCESS", "message", "Password reset successfully for " + request.identifier());
    }
}
