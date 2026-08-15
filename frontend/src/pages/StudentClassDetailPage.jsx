import { useCallback, useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, Clock, MapPin, CheckCircle2, XCircle, Calendar, RefreshCw, Smartphone } from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";
import { useAuth } from "../lib/AuthContext";
import { captureCalibratedLocation } from "../lib/location";

export default function StudentClassDetailPage() {
  const { classId } = useParams();
  const navigate = useNavigate();
  const notify = useToast();
  const { user } = useAuth();

  const [classInfo, setClassInfo] = useState(null);
  const [sessionList, setSessionList] = useState([]);
  const [myRecords, setMyRecords] = useState([]);
  const [activeSession, setActiveSession] = useState(null);
  const [claiming, setClaiming] = useState(false);
  const [busy, setBusy] = useState(false);

  const loadData = useCallback(async () => {
    try {
      // 1. Load enrolled classes
      const classes = await api("/api/classes/enrolled");
      const found = classes.find((c) => c.id === classId);
      if (found) setClassInfo(found);

      // 2. Load student's attendance records
      const records = await api("/api/attendance/me");
      const filteredRecords = records.filter((r) => r.classId === classId);
      setMyRecords(filteredRecords);

      // 3. Check active session for this class
      try {
        const active = await api(`/api/sessions/active?classId=${classId}`);
        setActiveSession(active);
      } catch {
        setActiveSession(null);
      }
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to load class details", "danger");
    }
  }, [classId, notify]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  async function handleClaimAttendance() {
    if (!activeSession) return;
    setClaiming(true);
    try {
      // Use the same calibrated GPS loop as the teacher capture.
      // It retries up to 6 times and rejects if accuracy > session radius.
      const radiusMeters = activeSession.radiusMeters || 20;
      const location = await captureCalibratedLocation(radiusMeters);

      let installId = localStorage.getItem("jarvisatt.deviceInstallId");
      if (!installId) {
        installId = "web-" + Math.random().toString(36).substring(2, 15);
        localStorage.setItem("jarvisatt.deviceInstallId", installId);
      }

      await api("/api/attendance/claim", {
        method: "POST",
        body: JSON.stringify({
          sessionId: activeSession.sessionId,
          latitude: location.latitude,
          longitude: location.longitude,
          accuracyMeters: location.accuracyMeters,
          capturedAt: location.capturedAt,
          deviceInstallId: installId,
        }),
      });

      notify("Attendance submitted & verified successfully!", "success");
      await loadData();
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to submit attendance", "danger");
    } finally {
      setClaiming(false);
    }
  }

  // Calculate Stats
  const totalMyRecords = myRecords.length;
  // Unique sessions recorded
  const uniqueSessionIds = new Set(myRecords.map((r) => r.sessionId));

  return (
    <div style={{ paddingBottom: 60 }}>
      {/* Back Button */}
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20 }}>
        <button type="button" className="btn btn-secondary" onClick={() => navigate("/student")}>
          <ArrowLeft size={16} /> Back to Dashboard
        </button>
      </div>

      {/* Class Header Card */}
      {classInfo && (
        <div className="panel glass-panel" style={{ border: "1px solid #00E6FF", marginBottom: 24 }}>
          <span className="badge badge-success" style={{ marginBottom: 8, fontSize: "0.8rem" }}>
            CODE: {classInfo.code}
          </span>
          <h1 style={{ fontSize: "1.8rem", fontWeight: 800, color: "#ffffff", margin: "4px 0" }}>
            {classInfo.subjectName || classInfo.subjectCode}
          </h1>
          <p style={{ color: "#00E6FF", fontWeight: 600, fontSize: "0.95rem", margin: "4px 0 12px" }}>
            Instructor: {classInfo.teacherName || "Faculty"} • {classInfo.subjectCode} ({classInfo.credits ? `${classInfo.credits} Credits` : ""})
          </p>
          <div style={{ display: "flex", gap: 16, color: "#94a3b8", fontSize: "0.85rem" }}>
            <span>Dept: {classInfo.department}</span>
            <span>{classInfo.academicSession}</span>
            <span>{classInfo.semester || "Semester N/A"}</span>
          </div>
        </div>
      )}

      {/* Live GPS Attendance Claim Banner */}
      {activeSession ? (
        <div className="panel glass-panel" style={{ background: "rgba(0, 255, 136, 0.08)", border: "1px solid #00FF88", marginBottom: 24, padding: 20 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 16 }}>
            <div>
              <span className="badge badge-success" style={{ marginBottom: 6 }}>
                LIVE GPS SESSION ACTIVE
              </span>
              <h3 style={{ color: "#ffffff", fontSize: "1.2rem", fontWeight: 800, margin: "4px 0" }}>
                Teacher is taking attendance now!
              </h3>
              <p style={{ color: "#94a3b8", fontSize: "0.85rem", margin: 0 }}>
                Radius: {activeSession.radiusMeters}m • Ensure GPS is turned ON.
              </p>
            </div>
            <button
              type="button"
              className="btn btn-primary"
              onClick={handleClaimAttendance}
              disabled={claiming}
              style={{ background: "linear-gradient(135deg, #00FF88, #00E6FF)", color: "#000", fontWeight: 900, padding: "12px 24px", fontSize: "1rem" }}
            >
              <MapPin size={18} /> {claiming ? "Verifying GPS..." : "Submit Attendance"}
            </button>
          </div>
        </div>
      ) : (
        <div className="panel glass-panel" style={{ border: "1px solid #213042", marginBottom: 24, padding: 16 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ color: "#94a3b8", fontSize: "0.9rem" }}>No active GPS session at this moment.</span>
            <button type="button" className="btn btn-secondary" onClick={loadData} style={{ fontSize: "0.8rem" }}>
              <RefreshCw size={14} /> Check Live Session
            </button>
          </div>
        </div>
      )}

      {/* Attendance Summary Stats Box */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))", gap: 16, marginBottom: 24 }}>
        <div className="panel glass-panel" style={{ border: "1px solid #213042", textAlign: "center", padding: 16 }}>
          <span style={{ color: "#94a3b8", fontSize: "0.8rem", display: "block" }}>TOTAL SESSIONS CONDUCTED</span>
          <span style={{ color: "#ffffff", fontSize: "1.8rem", fontWeight: 900, marginTop: 4, display: "block" }}>
            {myRecords.length}
          </span>
        </div>
        <div className="panel glass-panel" style={{ border: "1px solid #213042", textAlign: "center", padding: 16 }}>
          <span style={{ color: "#94a3b8", fontSize: "0.8rem", display: "block" }}>TOTAL ATTENDED</span>
          <span style={{ color: "#00FF88", fontSize: "1.8rem", fontWeight: 900, marginTop: 4, display: "block" }}>
            {totalMyRecords}
          </span>
        </div>
        <div className="panel glass-panel" style={{ border: "1px solid #213042", textAlign: "center", padding: 16 }}>
          <span style={{ color: "#94a3b8", fontSize: "0.8rem", display: "block" }}>ATTENDANCE RATE</span>
          <span style={{ color: "#00E6FF", fontSize: "1.8rem", fontWeight: 900, marginTop: 4, display: "block" }}>
            {myRecords.length > 0 ? "100%" : "0%"}
          </span>
        </div>
      </div>

      {/* Class Attendance Records Table */}
      <div className="panel glass-panel" style={{ border: "1px solid #213042" }}>
        <h2>
          <Calendar size={20} color="#00E6FF" /> Class Attendance Log
        </h2>

        {myRecords.length === 0 ? (
          <div style={{ textAlign: "center", padding: "32px", color: "#94a3b8" }}>
            No attendance records logged for this class yet.
          </div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table className="table" style={{ width: "100%", textAlign: "left" }}>
              <thead>
                <tr>
                  <th>Session Date</th>
                  <th>Attendance Status</th>
                  <th>Submitted Time</th>
                </tr>
              </thead>
              <tbody>
                {myRecords.map((r) => {
                  const d = new Date(r.scannedAt);
                  const isPresent = true; // All records in myRecords are verified attendances
                  return (
                    <tr key={r.id} style={{ borderBottom: "1px solid #213042" }}>
                      <td style={{ color: "#ffffff", fontWeight: 600 }}>{d.toLocaleDateString()}</td>
                      <td>
                        {isPresent ? (
                          <span className="badge badge-success" style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
                            <CheckCircle2 size={14} /> YES
                          </span>
                        ) : (
                          <span style={{ color: "#ef4444", fontWeight: 800, display: "inline-flex", alignItems: "center", gap: 4 }}>
                            <XCircle size={14} /> NO
                          </span>
                        )}
                      </td>
                      <td style={{ color: isPresent ? "#00FF88" : "#94a3b8", fontWeight: 600 }}>
                        {isPresent ? d.toLocaleTimeString() : "-"}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
