package com.jarvisatt.attendance.controller;

import com.jarvisatt.attendance.dto.ClassDtos.*;
import com.jarvisatt.attendance.security.UserPrincipal;
import com.jarvisatt.attendance.service.ClassService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/classes")
@RequiredArgsConstructor
public class ClassController {
    private final ClassService classService;

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    ClassResponse create(@Valid @RequestBody CreateClassRequest request, @AuthenticationPrincipal UserPrincipal principal) {
        return classService.create(request, principal);
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    List<ClassResponse> list(@AuthenticationPrincipal UserPrincipal principal) {
        return classService.teacherClasses(principal);
    }

    @GetMapping("/enrolled")
    @PreAuthorize("hasRole('STUDENT')")
    List<ClassResponse> listEnrolled(@AuthenticationPrincipal UserPrincipal principal) {
        return classService.studentClasses(principal);
    }
}
