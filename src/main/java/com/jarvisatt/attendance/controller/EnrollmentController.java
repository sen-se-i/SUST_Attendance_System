package com.jarvisatt.attendance.controller;

import com.jarvisatt.attendance.dto.ClassDtos.*;
import com.jarvisatt.attendance.security.UserPrincipal;
import com.jarvisatt.attendance.service.EnrollmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/classes")
@RequiredArgsConstructor
public class EnrollmentController {
    private final EnrollmentService enrollmentService;

    @PostMapping("/join")
    @PreAuthorize("hasRole('STUDENT')")
    JoinClassResponse join(@Valid @RequestBody JoinClassRequest request, @AuthenticationPrincipal UserPrincipal principal) {
        return enrollmentService.join(request, principal);
    }
}
