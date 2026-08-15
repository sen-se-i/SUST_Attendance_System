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
    JoinClassResponse joinDirect(@RequestBody JoinClassDirectRequest request, @AuthenticationPrincipal UserPrincipal principal) {
        if (request == null || request.effectiveCode().isBlank()) {
            throw new com.jarvisatt.attendance.exception.ApiException(org.springframework.http.HttpStatus.BAD_REQUEST, "Class Code is required");
        }
        return enrollmentService.joinDirect(request, principal);
    }
}
