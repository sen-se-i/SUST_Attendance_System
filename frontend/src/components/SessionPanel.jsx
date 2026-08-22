import { useEffect, useState } from "react";
import { Play, Square, MapPin, Timer, Radar } from "lucide-react";
import { captureCalibratedLocation } from "../lib/location";

export function SessionPanel({ session, onStart, onStop, busy }) {
  const [radius, setRadius] = useState(20);
  const [remaining, setRemaining] = useState(150);

  useEffect(() => {
    if (!session || !session.expiresAt) return;
    const interval = setInterval(() => {
      const diff = Math.max(0, Math.floor((new Date(session.expiresAt).getTime() - Date.now()) / 1000));
      setRemaining(diff);
    }, 1000);
    return () => clearInterval(interval);
  }, [session]);

  const handleStartWithLocation = async () => {
    try {
      const location = await captureCalibratedLocation(radius);
      onStart({
        ...location,
        radiusMeters: radius,
      });
    } catch (error) {
      const detail = error?.message ? ` ${error.message}` : "";
      alert(`Could not capture teacher GPS location.${detail} Please enable location permission and try again.`);
    }
  };

  return (
    <div className="panel glass-panel session-panel">
      <div className="toolbar">
        <h3 style={{ display: "flex", alignItems: "center", gap: "8px" }}>
          <Radar size={18} /> GPS Attendance Session
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
          <label className="form-label">
            Geofence Radius: <strong>{radius} Meters</strong>
          </label>
          <div style={{ display: "flex", gap: "10px", margin: "12px 0" }}>
            {[20, 50, 100].map((r) => (
              <button
                key={r}
                type="button"
                className={`btn ${radius === r ? "btn-primary" : "btn-secondary"}`}
                style={{ padding: "6px 16px", borderRadius: "9999px", fontSize: "0.85rem" }}
                onClick={() => setRadius(r)}
              >
                {r}m
              </button>
            ))}
          </div>
          <input
            type="range"
            min="20"
            max="100"
            step="5"
            value={radius}
            onChange={(e) => setRadius(Number(e.target.value))}
            style={{ width: "100%", accentColor: "var(--primary)" }}
          />
        </div>
      ) : (
        <div className="qr-stage" style={{ textAlign: "center", padding: "20px" }}>
          <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: "8px", fontWeight: "700", fontSize: "1.05rem" }}>
            <MapPin size={20} /> GEOFENCE ACTIVE ({session.radiusMeters || radius}m Radius)
          </div>
          <div style={{ margin: "12px 0", fontSize: "1.2rem", fontWeight: "700", display: "flex", justifyContent: "center", alignItems: "center", gap: "8px", color: "var(--danger)" }}>
            <Timer size={20} /> {remaining}s remaining (150s limit)
          </div>
          <p style={{ color: "var(--text-secondary)", fontSize: "0.88rem" }}>
            Students inside the {session.radiusMeters || radius}m perimeter can now click "Give Attendance" on their device.
          </p>
        </div>
      )}
    </div>
  );
}


