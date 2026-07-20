import { useCallback, useEffect, useRef, useState } from "react";
import { Play, Square } from "lucide-react";
import { fetchQrBlob } from "../lib/api";
import { useTickSocket } from "../lib/useTickSocket";

export function SessionPanel({ session, onStart, onStop, busy }) {
  const [tick, setTick] = useState(null);
  const [qrUrl, setQrUrl] = useState(null);
  const qrUrlRef = useRef(null);

  const handleTick = useCallback(async (message) => {
    setTick(message);
    try {
      const blob = await fetchQrBlob(message.sessionId);
      const nextUrl = URL.createObjectURL(blob);
      if (qrUrlRef.current) URL.revokeObjectURL(qrUrlRef.current);
      qrUrlRef.current = nextUrl;
      setQrUrl(nextUrl);
    } catch {
      // transient fetch failure, next tick will retry
    }
  }, []);

  useTickSocket(session?.sessionId, handleTick);

  useEffect(() => {
    return () => {
      if (qrUrlRef.current) URL.revokeObjectURL(qrUrlRef.current);
      qrUrlRef.current = null;
    };
  }, [session?.sessionId]);

  useEffect(() => {
    if (!session) {
      setTick(null);
      setQrUrl(null);
    }
  }, [session]);

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
            {tick ? `Tick ${tick.tickIndex + 1} · expires ${new Date(tick.expiresAt).toLocaleTimeString()}` : "Waiting for first tick..."}
          </p>
          {qrUrl && <img src={qrUrl} alt="Current attendance QR" className="qr-image" />}
          {tick?.qrPayload && <code className="payload-preview">{tick.qrPayload}</code>}
        </div>
      )}
    </div>
  );
}
