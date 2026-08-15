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

    @PostMapping("/claim")
    @PreAuthorize("hasRole('STUDENT')")
    VerifyScanResponse claim(@Valid @RequestBody ClaimAttendanceRequest request, @AuthenticationPrincipal UserPrincipal principal) {
        return attendanceService.claim(request, principal);
    }

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

    @GetMapping("/classes/{classId}/students/{studentId}")
    @PreAuthorize("hasRole('ADMIN')")
    List<AttendanceRecordResponse> studentClassHistory(@PathVariable UUID classId, @PathVariable UUID studentId) {
        return attendanceService.studentClassHistory(classId, studentId);
    }

    @PostMapping("/students/{studentId}/reset-device")
    @PreAuthorize("hasRole('ADMIN')")
    void resetDevice(@PathVariable UUID studentId) {
        attendanceService.resetStudentDevice(studentId);
    }

    @DeleteMapping("/classes/{classId}/students/{studentId}")
    @PreAuthorize("hasRole('ADMIN')")
    void deleteStudentClassHistory(@PathVariable UUID classId, @PathVariable UUID studentId) {
        attendanceService.deleteStudentClassHistory(classId, studentId);
    }

    @DeleteMapping("/records/{recordId}")
    @PreAuthorize("hasRole('ADMIN')")
    void deleteRecord(@PathVariable UUID recordId) {
        attendanceService.deleteAttendanceRecord(recordId);
    }

    @PostMapping("/records/batch-delete")
    @PreAuthorize("hasRole('ADMIN')")
    void deleteBatchRecords(@RequestBody List<UUID> recordIds) {
        attendanceService.deleteBatchAttendanceRecords(recordIds);
    }
}
