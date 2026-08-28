package com.jarvisatt.attendance.controller;

import com.jarvisatt.attendance.dto.ClassDtos.*;
import com.jarvisatt.attendance.security.UserPrincipal;
import com.jarvisatt.attendance.service.ClassStudentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/classes/{classId}/students")
@RequiredArgsConstructor
public class ClassStudentController {
    private final ClassStudentService classStudentService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public List<ClassStudentResponse> listStudents(@PathVariable UUID classId, @AuthenticationPrincipal UserPrincipal principal) {
        return classStudentService.listStudents(classId, principal);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public Map<String, String> addStudent(@PathVariable UUID classId, @Valid @RequestBody AddStudentRequest request,
                                         @AuthenticationPrincipal UserPrincipal principal) {
        classStudentService.addStudent(classId, request.registrationNo(), principal);
        return Map.of("status", "ADDED", "registrationNo", request.registrationNo());
    }

    @DeleteMapping("/{registrationNo}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public Map<String, String> removeStudent(@PathVariable UUID classId, @PathVariable String registrationNo,
                                            @AuthenticationPrincipal UserPrincipal principal) {
        classStudentService.removeStudent(classId, registrationNo, principal);
        return Map.of("status", "REMOVED", "registrationNo", registrationNo);
    }
}
