import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Plus, RefreshCw, BookOpen, ChevronRight, Clock, User, CheckCircle2 } from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";
import { useAuth } from "../lib/AuthContext";
import { getDeviceInstallId } from "../lib/deviceId";
import { AttendanceTable } from "../components/AttendanceTable";
import { captureCalibratedLocation } from "../lib/location";

const initialJoinForm = { classCode: "", registrationNo: "" };

export default function StudentDashboard() {
  const navigate = useNavigate();
  const notify = useToast();
  const { user } = useAuth();

  const [classes, setClasses] = useState([]);
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [classCode, setClassCode] = useState("");
  const [busy, setBusy] = useState(false);

  const loadClasses = useCallback(async () => {
    try {
      setClasses(await api("/api/classes/enrolled"));
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to load enrolled classes", "danger");
    }
  }, [notify]);

  useEffect(() => {
    loadClasses();
  }, [loadClasses]);

  async function handleJoinClass(e) {
    e.preventDefault();
    if (!classCode.trim()) return;

    setBusy(true);
    try {
      await api("/api/classes/join", {
        method: "POST",
        body: JSON.stringify({ classCode: classCode.trim() }),
      });
      notify("Enrolled in class successfully!", "success");
      setShowJoinModal(false);
      setClassCode("");
      await loadClasses();
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
    <div style={{ paddingBottom: 100 }}>

      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 18, flexWrap: "wrap", gap: 10 }}>
        <div>
          <h1 style={{ fontSize: "1.4rem", fontWeight: 800, color: "#ffffff", margin: 0 }}>My Enrolled Classes</h1>
          <p style={{ color: "#94a3b8", fontSize: "0.82rem", margin: "2px 0 0" }}>
            Select a class to view attendance records and live GPS sessions.
          </p>
        </div>
        <button type="button" className="btn btn-secondary" style={{ padding: "6px 14px", fontSize: "0.82rem" }} onClick={loadClasses}>
          <RefreshCw size={14} /> Refresh
        </button>
      </div>

      <div className="panel glass-panel scanner-panel">
        <h2>
          <Navigation size={18} /> GPS Attendance Verification
        </h2>

        {activeSession ? (
          <div style={{ textAlign: "center", padding: "18px", background: "#f8fafc", border: "1px solid var(--border-light)", borderRadius: "var(--radius-md)", margin: "12px 0" }}>
            <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: "8px", fontWeight: "700", color: "var(--text-primary)" }}>
              <MapPin size={18} /> SESSION ACTIVE ({activeSession.radiusMeters || 20}m Radius)
            </div>
            <p style={{ color: "var(--text-secondary)", fontSize: "0.85rem", margin: "8px 0 14px" }}>
              Ensure your device GPS location is turned on to mark present.
            </p>

            {isAlreadyAttended ? (
              <div className="badge badge-success" style={{ padding: "8px 16px", fontSize: "0.9rem" }}>
                <CircleCheckBig size={16} /> Attendance Verified & Recorded!
              </div>
            ) : (
              <button
                type="button"
                className="btn btn-primary"
                style={{ width: "100%", padding: "12px", fontSize: "0.95rem" }}
                onClick={handleClaimAttendance}
                disabled={claiming}
              >
                {claiming ? "Verifying GPS Location..." : "Give Attendance (GPS)"}
              </button>
            )}
          </div>
        ) : (
          <div style={{ textAlign: "center", padding: "28px 16px", color: "var(--text-muted)" }}>
            <MapPin size={32} style={{ marginBottom: "8px", opacity: 0.6 }} />
            <p style={{ fontWeight: "700", color: "var(--text-primary)" }}>No Active Session</p>
            <p style={{ fontSize: "0.85rem", marginTop: "4px" }}>Select a class above and check when your teacher starts an attendance session.</p>
          </div>
        )}
      </div>

              <div style={{ display: "flex", gap: 12, justifyContent: "flex-end" }}>
                <button type="button" className="btn btn-secondary" onClick={() => setShowJoinModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={busy || !classCode.trim()}>
                  Join Class
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

