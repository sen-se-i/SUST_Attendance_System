import { useEffect, useState } from "react";
import { Play, Square, MapPin, Timer, Radar } from "lucide-react";

export function SessionPanel({ session, onStart, onStop, busy }) {
  const [radius, setRadius] = useState(10);
  const [remaining, setRemaining] = useState(150);

  useEffect(() => {
    if (!session || !session.expiresAt) return;
    const interval = setInterval(() => {
      const diff = Math.max(0, Math.floor((new Date(session.expiresAt).getTime() - Date.now()) / 1000));
      setRemaining(diff);
    }, 1000);
    return () => clearInterval(interval);
  }, [session]);

  const handleStartWithLocation = () => {
    if (!navigator.geolocation) {
      alert("Geolocation is not supported by your browser");
      onStart({ latitude: 23.777176, longitude: 90.399452, radiusMeters: radius });
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        onStart({
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
          radiusMeters: radius,
        });
      },
      () => {
        // Fallback demo location if user denies or emulator
        onStart({ latitude: 23.777176, longitude: 90.399452, radiusMeters: radius });
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  return (
    <div className="panel glass-panel session-panel" style={{ border: "1px solid rgba(99, 102, 241, 0.4)" }}>
      <div className="toolbar">
        <h3 style={{ display: "flex", alignItems: "center", gap: "8px" }}>
          <Radar size={20} color="#818cf8" /> GPS Attendance Geofence Session
        </h3>
        {session ? (
          <button type="button" className="btn btn-danger" onClick={onStop} disabled={busy}>
            <Square size={16} /> End Session Now
          </button>
        ) : (
          <button type="button" className="btn btn-primary" onClick={handleStartWithLocation} disabled={busy}>
            <Play size={16} /> Start GPS Session ({radius}m)
          </button>
        )}
      </div>

      {!session ? (
        <div style={{ marginTop: "16px" }}>
          <label className="form-label" style={{ fontWeight: "bold", color: "#e2e8f0" }}>
            Select Geofence Radius: <span style={{ color: "#818cf8" }}>{radius} Meters</span>
          </label>
          <div style={{ display: "flex", gap: "8px", margin: "12px 0" }}>
            {[5, 10, 20, 50, 100].map((r) => (
              <button
                key={r}
                type="button"
                className={`btn ${radius === r ? "btn-primary" : "btn-secondary"}`}
                style={{ padding: "6px 16px", borderRadius: "20px" }}
                onClick={() => setRadius(r)}
              >
                {r}m
              </button>
            ))}
          </div>
          <input
            type="range"
            min="5"
            max="100"
            step="5"
            value={radius}
            onChange={(e) => setRadius(Number(e.target.value))}
            style={{ width: "100%", accentColor: "#6366f1" }}
          />
        </div>
      ) : (
        <div className="qr-stage" style={{ textAlign: "center", padding: "20px", background: "rgba(15, 15, 26, 0.6)", borderRadius: "12px" }}>
          <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: "10px", color: "#4ade80", fontSize: "1.1rem", fontWeight: "bold" }}>
            <MapPin size={22} color="#38bdf8" /> GEOFENCE ACTIVE ({session.radiusMeters || radius}m Radius)
          </div>
          <div style={{ margin: "16px 0", color: "#ef4444", fontSize: "1.3rem", fontWeight: "bold", display: "flex", justifyContent: "center", alignItems: "center", gap: "6px" }}>
            <Timer size={22} /> {remaining}s remaining (150s limit)
          </div>
          <p style={{ color: "#94a3b8", fontSize: "0.9rem" }}>
            Students inside the {session.radiusMeters || radius}m perimeter can now click "Give Attendance" on their device.
          </p>
        </div>
      )}
    </div>
  );
}
