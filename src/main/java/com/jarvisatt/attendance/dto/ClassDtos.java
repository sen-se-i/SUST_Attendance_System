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
        Double credits
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
        java.time.OffsetDateTime lastSessionAt
    ) {}

    public record RosterRequest(java.util.List<@NotBlank String> registrationNos) {}
    public record JoinClassDirectRequest(String classCode, String code) {
        public JoinClassDirectRequest(String classCode) {
            this(classCode, null);
        }
        public String effectiveCode() {
            if (classCode != null && !classCode.isBlank()) return classCode.trim();
            if (code != null && !code.isBlank()) return code.trim();
            return "";
        }
    }
    public record JoinClassResponse(UUID enrollmentId, UUID classId, String status) {}
    public record EnrolledStudentResponse(String registrationNo, String name, String status, java.time.OffsetDateTime joinedAt) {}
    public record RosterEntryResponse(String registrationNo, boolean joined) {}
}
