package com.jarvisatt.attendance.controller;

import com.jarvisatt.attendance.dto.ClassDtos.RosterEntryResponse;
import com.jarvisatt.attendance.dto.ClassDtos.RosterRequest;
import com.jarvisatt.attendance.security.UserPrincipal;
import com.jarvisatt.attendance.service.RosterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/classes/{classId}/roster")
@RequiredArgsConstructor
public class RosterController {
    private final RosterService rosterService;

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    Map<String, Integer> add(@PathVariable UUID classId, @Valid @RequestBody RosterRequest request,
                             @AuthenticationPrincipal UserPrincipal principal) {
        return Map.of("accepted", rosterService.addRoster(classId, request, principal));
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    List<RosterEntryResponse> list(@PathVariable UUID classId, @AuthenticationPrincipal UserPrincipal principal) {
        return rosterService.listRoster(classId, principal);
    }
}
