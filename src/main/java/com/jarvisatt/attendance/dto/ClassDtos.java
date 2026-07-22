package com.jarvisatt.attendance.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public final class ClassDtos {
    private ClassDtos() {}

    public record CreateClassRequest(@NotBlank String department, @NotBlank String academicSession, @NotBlank String subjectCode) {}
    public record ClassResponse(UUID id, String code, String department, String academicSession, String subjectCode) {}
    public record RosterRequest(java.util.List<@NotBlank String> registrationNos) {}
    public record JoinClassRequest(@NotBlank String classCode, @NotBlank String registrationNo) {}
    public record JoinClassResponse(UUID enrollmentId, UUID classId, String status) {}
    public record RosterEntryResponse(String registrationNo, boolean joined) {}
}
