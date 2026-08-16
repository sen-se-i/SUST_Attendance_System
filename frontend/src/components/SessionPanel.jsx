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
    <div className="panel glass-panel session-panel" style={{ border: "1px solid rgba(0, 230, 255, 0.35)", boxShadow: "0 0 20px rgba(0, 230, 255, 0.1)" }}>
      <div className="toolbar">
        <h3 style={{ display: "flex", alignItems: "center", gap: "8px", color: "#ffffff" }}>
          <Radar size={20} color="#00E6FF" /> GPS Attendance Geofence Session
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
            Select Geofence Radius: <span style={{ color: "#00E6FF" }}>{radius} Meters</span>
          </label>
          <div style={{ display: "flex", gap: "8px", margin: "12px 0" }}>
            {[20, 50, 100].map((r) => (
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
            min="20"
            max="100"
            step="5"
            value={radius}
            onChange={(e) => setRadius(Number(e.target.value))}
            style={{ width: "100%", accentColor: "#00E6FF" }}
          />
        </div>
      ) : (
        <div className="qr-stage" style={{ textAlign: "center", padding: "20px", background: "rgba(10, 16, 26, 0.8)", border: "1px solid #213042", borderRadius: "12px" }}>
          <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: "10px", color: "#00FF88", fontSize: "1.1rem", fontWeight: "bold" }}>
            <MapPin size={22} color="#00E6FF" /> GEOFENCE ACTIVE ({session.radiusMeters || radius}m Radius)
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

