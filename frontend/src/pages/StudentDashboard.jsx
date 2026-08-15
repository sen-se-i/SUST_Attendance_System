import { useCallback, useEffect, useState } from "react";
import { CircleCheckBig, GraduationCap, School, MapPin, Navigation, RefreshCw } from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";
import { useAuth } from "../lib/AuthContext";
import { getDeviceInstallId } from "../lib/deviceId";
import { AttendanceTable } from "../components/AttendanceTable";
import { captureCalibratedLocation } from "../lib/location";

const initialJoinForm = { classCode: "", registrationNo: "" };

export default function StudentDashboard() {
  const { user } = useAuth();
  const notify = useToast();
  const [joinForm, setJoinForm] = useState(() => ({ ...initialJoinForm, registrationNo: user?.registrationNo || "" }));
  const [deviceInstallId] = useState(getDeviceInstallId);
  const [attendance, setAttendance] = useState([]);
  const [joinedClasses, setJoinedClasses] = useState([]);
  const [selectedClassId, setSelectedClassId] = useState("");
  const [activeSession, setActiveSession] = useState(null);
  const [busy, setBusy] = useState(false);
  const [claiming, setClaiming] = useState(false);
  const [lastClaimResult, setLastClaimResult] = useState(null);

  const loadAttendance = useCallback(async () => {
    try {
      setAttendance(await api("/api/attendance/me"));
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to load attendance", "danger");
    }
  }, [notify]);

  const loadJoinedClasses = useCallback(async () => {
    try {
      const classes = await api("/api/classes/enrolled");
      setJoinedClasses(classes);
      if (classes.length > 0 && !selectedClassId) {
        setSelectedClassId(classes[0].id);
      }
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to load joined classes", "danger");
    }
  }, [notify, selectedClassId]);

  const checkActiveSession = useCallback(async () => {
    if (!selectedClassId) {
      setActiveSession(null);
      return;
    }
    try {
      const session = await api(`/api/sessions/active?classId=${selectedClassId}`);
      setActiveSession(session);
    } catch (error) {
      setActiveSession(null);
    }
  }, [selectedClassId]);

  useEffect(() => {
    loadAttendance();
    loadJoinedClasses();
  }, [loadAttendance, loadJoinedClasses]);

  useEffect(() => {
    checkActiveSession();
  }, [checkActiveSession]);

  async function handleJoin(event) {
    event.preventDefault();
    setBusy(true);
    try {
      await api("/api/classes/join", { method: "POST", body: JSON.stringify(joinForm) });
      notify("Class joined.", "success");
      await loadJoinedClasses();
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to join class", "danger");
    } finally {
      setBusy(false);
    }
  }

  async function handleClaimAttendance() {
    if (!activeSession) return;
    setClaiming(true);

    try {
      const location = await captureCalibratedLocation(activeSession.radiusMeters || 20);
      const result = await api("/api/attendance/claim", {
        method: "POST",
        body: JSON.stringify({
          sessionId: activeSession.sessionId,
          latitude: location.latitude,
          longitude: location.longitude,
          accuracyMeters: location.accuracyMeters,
          capturedAt: location.capturedAt,
          deviceInstallId,
        }),
      });
      setLastClaimResult(result);
      notify(`Attendance Registered! (${result.distanceMeters?.toFixed(1)}m from teacher, +/-${result.accuracyMeters?.toFixed(1)}m accuracy)`, "success");
      await loadAttendance();
    } catch (error) {
      notify(error instanceof ApiError ? error.message : `Could not verify GPS location. ${error?.message || "Please enable location permission and try again."}`, "danger");
    } finally {
      setClaiming(false);
    }
  }

  const isAlreadyAttended = activeSession && attendance.some((r) => r.sessionId === activeSession.sessionId);

  return (
    <div className="student-grid">
      <form className="panel glass-panel" onSubmit={handleJoin}>
        <h2>
          <School size={18} /> Join Class
        </h2>
        <div className="form-group">
          <label className="form-label" htmlFor="classCode">
            Class Code
          </label>
          <input
            id="classCode"
            className="form-input"
            maxLength={6}
            required
            placeholder="8K2P0X"
            value={joinForm.classCode}
            onChange={(e) => setJoinForm((f) => ({ ...f, classCode: e.target.value.toUpperCase() }))}
          />
        </div>
        <div className="form-group">
          <label className="form-label" htmlFor="registrationNo">
            Registration No
          </label>
          <input
            id="registrationNo"
            className="form-input"
            required
            value={joinForm.registrationNo}
            onChange={(e) => setJoinForm((f) => ({ ...f, registrationNo: e.target.value }))}
          />
        </div>
        <button type="submit" className="btn btn-primary" disabled={busy}>
          Join
        </button>
      </form>

      <div className="panel glass-panel">
        <div className="toolbar">
          <h2>
            <GraduationCap size={18} /> Joined Classes
          </h2>
          <button type="button" className="btn btn-secondary" onClick={checkActiveSession}>
            <RefreshCw size={14} /> Check Active Session
          </button>
        </div>
        {joinedClasses.length === 0 ? (
          <p className="empty-state">You haven't joined any classes yet.</p>
        ) : (
          <div className="list">
            {joinedClasses.map((item) => (
              <button
                key={item.id}
                type="button"
                className={`list-item joined-class-item ${selectedClassId === item.id ? "active" : ""}`}
                onClick={() => setSelectedClassId(item.id)}
              >
                {item.subjectCode} · {item.department}
                <span className="subtitle"> — code {item.code}</span>
              </button>
            ))}
          </div>
        )}
      </div>

      <div className="panel glass-panel scanner-panel" style={{ border: "1px solid rgba(0, 230, 255, 0.35)", boxShadow: "0 0 20px rgba(0, 230, 255, 0.08)" }}>
        <h2>
          <Navigation size={18} color="#00E6FF" /> GPS Attendance Verification
        </h2>

        {activeSession ? (
          <div style={{ textAlign: "center", padding: "16px", background: "rgba(10, 16, 26, 0.8)", border: "1px solid #213042", borderRadius: "12px", margin: "16px 0" }}>
            <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: "8px", color: "#00FF88", fontWeight: "bold" }}>
              <MapPin size={20} color="#00E6FF" /> SESSION ACTIVE ({activeSession.radiusMeters || 20}m Radius)
            </div>
            <p style={{ color: "#94a3b8", fontSize: "0.85rem", margin: "8px 0 16px" }}>
              Ensure your phone location / GPS is turned on to mark present.
            </p>

            {isAlreadyAttended ? (
              <div className="badge badge-success" style={{ padding: "10px 16px", fontSize: "0.95rem" }}>
                <CircleCheckBig size={18} /> Attendance Verified & Recorded!
              </div>
            ) : (
              <button
                type="button"
                className="btn btn-primary"
                style={{ width: "100%", padding: "14px", fontSize: "1.05rem" }}
                onClick={handleClaimAttendance}
                disabled={claiming}
              >
                {claiming ? "Verifying GPS Location..." : "Give Attendance (GPS)"}
              </button>
            )}
          </div>
        ) : (
          <div style={{ textAlign: "center", padding: "24px", color: "#94a3b8" }}>
            <MapPin size={36} color="#3B4D61" style={{ marginBottom: "8px" }} />
            <p style={{ fontWeight: "bold", color: "#FFFFFF" }}>No Active Session</p>
            <p style={{ fontSize: "0.85rem" }}>Select a class above and check when your teacher starts an attendance session.</p>
          </div>
        )}
      </div>

      <div className="panel glass-panel">
        <h2>My Attendance</h2>
        <AttendanceTable rows={attendance} emptyLabel="No attendance records yet." showSubject />
      </div>
    </div>
  );
}
