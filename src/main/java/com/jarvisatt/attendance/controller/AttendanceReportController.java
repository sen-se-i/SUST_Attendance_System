package com.jarvisatt.attendance.controller;

import com.jarvisatt.attendance.dto.ClassDtos.MatrixReportResponse;
import com.jarvisatt.attendance.security.UserPrincipal;
import com.jarvisatt.attendance.service.AttendanceExportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

@RestController
@RequestMapping("/api/classes/{classId}/report")
@RequiredArgsConstructor
public class AttendanceReportController {
    private final AttendanceExportService attendanceExportService;

    @GetMapping("/matrix")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public MatrixReportResponse getMatrixReport(@PathVariable UUID classId, @AuthenticationPrincipal UserPrincipal principal) {
        return attendanceExportService.generateMatrixReport(classId, principal);
    }

    @GetMapping("/csv")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<byte[]> downloadCsv(@PathVariable UUID classId, @AuthenticationPrincipal UserPrincipal principal) {
        String csv = attendanceExportService.generateCsv(classId, principal);
        byte[] bytes = csv.getBytes(StandardCharsets.UTF_8);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"attendance_report_" + classId + ".csv\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(bytes);
    }
}
