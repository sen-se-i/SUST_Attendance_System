import { useEffect, useRef, useState } from "react";
import { Play, Square } from "lucide-react";
import { api, fetchQrBlob } from "../lib/api";

// Poll the backend for the current tick and QR image over plain HTTP. This does
// not rely on the WebSocket, so the projector QR keeps refreshing as long as the
// REST API is reachable.
const POLL_INTERVAL_MS = 1000;

export function SessionPanel({ session, onStart, onStop, onEnded, busy }) {
  const [tick, setTick] = useState(null);
  const [error, setError] = useState(null);
  const [qrUrl, setQrUrl] = useState(null);
  const qrUrlRef = useRef(null);
  const hasTickedRef = useRef(false);

  const sessionId = session?.sessionId;

  useEffect(() => {
    if (!sessionId) {
      setTick(null);
      setError(null);
      setQrUrl(null);
      hasTickedRef.current = false;
      return undefined;
    }

    let cancelled = false;

    async function poll() {
      try {
        const current = await api(`/api/sessions/${sessionId}/current`);
        if (cancelled) return;

        const tickActive = current.tickIndex !== null && current.tickIndex !== undefined;
        if (tickActive) {
          hasTickedRef.current = true;
        } else if (hasTickedRef.current) {
          // The session was ticking and is now WAITING again — it ran out its
          // ticks (or was stopped elsewhere) rather than never having started.
          onEnded();
          return;
        }

        setTick(current);
        setError(null);

        if (tickActive) {
          const blob = await fetchQrBlob(sessionId);
          if (cancelled) return;
          const nextUrl = URL.createObjectURL(blob);
          if (qrUrlRef.current) URL.revokeObjectURL(qrUrlRef.current);
          qrUrlRef.current = nextUrl;
          setQrUrl(nextUrl);
        }
      } catch (err) {
        if (!cancelled) setError(err.message);
      }
    }

    poll();
    const timer = setInterval(poll, POLL_INTERVAL_MS);

    return () => {
      cancelled = true;
      clearInterval(timer);
      if (qrUrlRef.current) URL.revokeObjectURL(qrUrlRef.current);
      qrUrlRef.current = null;
    };
  }, [sessionId, onEnded]);

  const hasTick = tick && tick.tickIndex !== null && tick.tickIndex !== undefined;

  return (
    <div className="panel glass-panel session-panel">
      <div className="toolbar">
        <h3>Live Session</h3>
        {session ? (
          <button type="button" className="btn btn-danger" onClick={onStop} disabled={busy}>
            <Square size={16} /> Stop
          </button>
        ) : (
          <button type="button" className="btn btn-primary" onClick={onStart} disabled={busy}>
            <Play size={16} /> Start Attendance
          </button>
        )}
      </div>

      {session && (
        <div className="qr-stage">
          <p className="tick-status">
            {error
              ? error
              : hasTick
                ? `Tick ${tick.tickIndex + 1} · expires ${new Date(tick.expiresAt).toLocaleTimeString()}`
                : "Waiting for first QR code…"}
          </p>
          {qrUrl && <img src={qrUrl} alt="Current attendance QR" className="qr-image" />}
          {hasTick && tick.qrPayload && <code className="payload-preview">{tick.qrPayload}</code>}
        </div>
      )}
    </div>
  );
}
