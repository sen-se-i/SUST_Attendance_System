package com.jarvisatt.attendance.session;

import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

public class SessionRuntimeState {
    private final AtomicInteger nextTick = new AtomicInteger();
    private final AtomicReference<CurrentTick> currentTick = new AtomicReference<>();
    private ScheduledFuture<?> future;

    public int nextTickIndex() {
        return nextTick.getAndIncrement();
    }

    public AtomicReference<CurrentTick> currentTick() {
        return currentTick;
    }

    public ScheduledFuture<?> future() {
        return future;
    }

    public void future(ScheduledFuture<?> future) {
        this.future = future;
    }
}
