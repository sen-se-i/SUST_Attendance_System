package com.jarvisatt.attendance.session;

import com.jarvisatt.attendance.crypto.AesPayloadCipher;
import com.jarvisatt.attendance.crypto.HmacTokenService;
import com.jarvisatt.attendance.crypto.TickPayload;
import com.jarvisatt.attendance.domain.ClassSession;
import com.jarvisatt.attendance.domain.ClassSessionStatus;
import com.jarvisatt.attendance.domain.QrTick;
import com.jarvisatt.attendance.repository.ClassSessionRepository;
import com.jarvisatt.attendance.repository.QrTickRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Duration;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledFuture;

@Service
@RequiredArgsConstructor
public class SessionEngine {
    private final Map<UUID, SessionRuntimeState> states = new ConcurrentHashMap<>();
    private final ThreadPoolTaskScheduler taskScheduler;
    private final TransactionTemplate transactionTemplate;
    private final QrTickRepository qrTickRepository;
    private final ClassSessionRepository classSessionRepository;
    private final HmacTokenService hmacTokenService;
    private final AesPayloadCipher aesPayloadCipher;
    private final SimpMessagingTemplate messagingTemplate;

    public void start(ClassSession session) {
        SessionRuntimeState state = new SessionRuntimeState();
        states.put(session.getId(), state);
        Runnable rotate = () -> rotate(session.getId());
        // Tick 0 is fired manually below, synchronously, inside the caller's still-open
        // transaction so it can see the just-created session row. The scheduler's own
        // first execution must NOT also fire at "now" — it runs on a separate thread with
        // no transaction, so it would read the session before this transaction commits,
        // see it as missing, and call stop(), wiping the state we just created. Delaying
        // the first scheduled run by one full interval avoids that race entirely.
        Duration interval = Duration.ofSeconds(session.getTickIntervalSeconds());
        ScheduledFuture<?> future = taskScheduler.scheduleAtFixedRate(rotate, Instant.now().plus(interval), interval);
        state.future(future);
        rotate.run();
    }

    public Optional<CurrentTick> currentTick(UUID sessionId) {
        return Optional.ofNullable(states.get(sessionId)).map(state -> state.currentTick().get());
    }

    public boolean isRunning(UUID sessionId) {
        return states.containsKey(sessionId);
    }

    public Optional<String> currentPayload(UUID sessionId) {
        return currentTick(sessionId).map(CurrentTick::qrPayload);
    }

    public void stop(UUID sessionId) {
        SessionRuntimeState state = states.remove(sessionId);
        if (state != null && state.future() != null) {
            state.future().cancel(false);
        }
        transactionTemplate.executeWithoutResult(status -> classSessionRepository.findById(sessionId).ifPresent(session -> {
            session.setStatus(ClassSessionStatus.ENDED);
            session.setEndedAt(OffsetDateTime.now());
        }));
    }

    private void rotate(UUID sessionId) {
        SessionRuntimeState state = states.get(sessionId);
        if (state == null) {
            return;
        }
        ClassSession session = classSessionRepository.findById(sessionId).orElse(null);
        if (session == null || session.getStatus() != ClassSessionStatus.ACTIVE) {
            stop(sessionId);
            return;
        }
        int tickIndex = state.nextTickIndex();
        if (tickIndex >= session.getTotalTicks()) {
            stop(sessionId);
            return;
        }

        CurrentTick tick = transactionTemplate.execute(status -> {
            OffsetDateTime now = OffsetDateTime.now();
            CurrentTick previous = state.currentTick().get();
            if (previous != null) {
                qrTickRepository.expireNow(previous.tickId(), now);
            }
            String nonce = hmacTokenService.nonce();
            String token = hmacTokenService.token(sessionId, tickIndex, nonce);
            String hash = hmacTokenService.hash(token);
            QrTick row = new QrTick();
            row.setSession(session);
            row.setTickIndex(tickIndex);
            row.setTokenHash(hash);
            row.setIssuedAt(now);
            row.setExpiresAt(now.plusSeconds(session.getTickIntervalSeconds()));
            qrTickRepository.saveAndFlush(row);
            String payload = aesPayloadCipher.encrypt(new TickPayload(sessionId, tickIndex, nonce));
            return new CurrentTick(row.getId(), tickIndex, hash, payload, row.getExpiresAt());
        });
        state.currentTick().set(tick);
        messagingTemplate.convertAndSend("/topic/sessions/" + sessionId + "/ticks",
                new TickBroadcastMessage(sessionId, tick.tickIndex(), tick.qrPayload(), tick.expiresAt()));
    }
}
