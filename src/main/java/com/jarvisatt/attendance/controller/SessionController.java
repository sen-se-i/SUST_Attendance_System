package com.jarvisatt.attendance.controller;

import com.jarvisatt.attendance.dto.SessionDtos.*;
import com.jarvisatt.attendance.security.UserPrincipal;
import com.jarvisatt.attendance.service.QrCodeService;
import com.jarvisatt.attendance.service.SessionLifecycleService;
import com.jarvisatt.attendance.session.SessionEngine;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api/sessions")
@RequiredArgsConstructor
public class SessionController {
    private final SessionLifecycleService sessionLifecycleService;
    private final SessionEngine sessionEngine;
    private final QrCodeService qrCodeService;

    @PostMapping("/start")
    @PreAuthorize("hasRole('ADMIN')")
    SessionResponse start(@Valid @RequestBody StartSessionRequest request, @AuthenticationPrincipal UserPrincipal principal) {
        return sessionLifecycleService.start(request, principal);
    }

    @PostMapping("/{sessionId}/stop")
    @PreAuthorize("hasRole('ADMIN')")
    Map<String, String> stop(@PathVariable UUID sessionId, @AuthenticationPrincipal UserPrincipal principal) {
        sessionLifecycleService.stop(sessionId, principal);
        return Map.of("status", "ENDED");
    }

    @GetMapping("/{sessionId}/current")
    @PreAuthorize("hasRole('ADMIN')")
    CurrentTickResponse current(@PathVariable UUID sessionId) {
        return sessionEngine.currentTick(sessionId)
                .map(tick -> new CurrentTickResponse(sessionId, tick.tickIndex(), tick.qrPayload(), "ACTIVE", tick.expiresAt()))
                .orElseGet(() -> new CurrentTickResponse(sessionId, null, null, "WAITING", OffsetDateTime.now()));
    }

    @GetMapping(value = "/{sessionId}/qr.png", produces = MediaType.IMAGE_PNG_VALUE)
    @PreAuthorize("hasRole('ADMIN')")
    ResponseEntity<byte[]> qr(@PathVariable UUID sessionId) {
        String payload = sessionEngine.currentPayload(sessionId).orElse("waiting");
        return ResponseEntity.ok()
                .cacheControl(CacheControl.maxAge(0, TimeUnit.SECONDS).mustRevalidate().cachePrivate())
                .contentType(MediaType.IMAGE_PNG)
                .body(qrCodeService.png(payload, 420));
    }
}
