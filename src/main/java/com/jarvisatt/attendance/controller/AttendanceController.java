package com.jarvisatt.attendance.controller;

import com.jarvisatt.attendance.dto.AttendanceDtos.*;
import com.jarvisatt.attendance.security.UserPrincipal;
import com.jarvisatt.attendance.service.AttendanceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/attendance")
@RequiredArgsConstructor
public class AttendanceController {
    private final AttendanceService attendanceService;

    @PostMapping("/verify")
    @PreAuthorize("hasRole('STUDENT')")
    VerifyScanResponse verify(@Valid @RequestBody VerifyScanRequest request, @AuthenticationPrincipal UserPrincipal principal) {
        return attendanceService.verify(request, principal);
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('STUDENT')")
    List<AttendanceRecordResponse> me(@AuthenticationPrincipal UserPrincipal principal) {
        return attendanceService.studentHistory(principal);
    }

    @GetMapping("/classes/{classId}")
    @PreAuthorize("hasRole('ADMIN')")
    List<AttendanceRecordResponse> classHistory(@PathVariable UUID classId, @AuthenticationPrincipal UserPrincipal principal) {
        return attendanceService.classHistory(classId, principal);
    }
}
