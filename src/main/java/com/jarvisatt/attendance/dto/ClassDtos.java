package com.jarvisatt.attendance.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public final class ClassDtos {
    private ClassDtos() {}

    public record CreateClassRequest(
        @NotBlank String department,
        @NotBlank String academicSession,
        @NotBlank String semester,
        @NotBlank String subjectCode,
        String subjectName,
        Double credits,
        UUID teacherId
    ) {}

    public record ClassResponse(
        UUID id,
        String code,
        String department,
        String academicSession,
        String semester,
        String subjectCode,
        String subjectName,
        Double credits,
        String teacherName,
        UUID teacherId,
        String status,
        int enrolledCount,
        int totalSessions,
        java.time.OffsetDateTime lastSessionAt
    ) {}

    public record AddStudentRequest(@NotBlank String registrationNo) {}
    public record AddStudentsBatchRequest(java.util.List<@NotBlank String> registrationNos) {}
    public record ClassStudentResponse(String registrationNo, String email, String status, java.time.OffsetDateTime joinedAt) {}

    public record SessionColumn(UUID sessionId, java.time.OffsetDateTime startedAt, int attendanceCount) {}
    public record StudentRow(String registrationNo, java.util.List<Boolean> attendance, int totalAttended, double percentage) {}
    public record MatrixReportResponse(
        UUID classId,
        String classCode,
        String subjectName,
        String subjectCode,
        String department,
        String academicSession,
        String semester,
        String teacherName,
        int totalSessions,
        int totalStudents,
        double averageAttendancePercentage,
        java.util.List<SessionColumn> sessions,
        java.util.List<StudentRow> studentRows,
        java.util.List<Integer> sessionAttendanceCounts
    ) {}
}

