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

      const classes = await api("/api/classes/enrolled");
      const found = classes.find((c) => c.id === classId);
      if (found) setClassInfo(found);

      try {
        const sessions = await api(`/api/sessions/class/${classId}`);
        setSessionList(sessions);
      } catch {
        setSessionList([]);
      }

      const records = await api("/api/attendance/me");
      const filteredRecords = records.filter((r) => r.classId === classId);
      setMyRecords(filteredRecords);

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

  const totalConducted = sessionList.length;
  const totalAttended = myRecords.length;
  const attendanceRate = totalConducted > 0 ? Math.round((totalAttended / totalConducted) * 100) : 0;

  return (
    <div style={{ paddingBottom: 60 }}>

      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
        <button type="button" className="btn btn-secondary" style={{ padding: "6px 14px", fontSize: "0.85rem" }} onClick={() => navigate("/student")}>
          <ArrowLeft size={15} /> Back to Dashboard
        </button>
      </div>

      {classInfo && (
        <div className="panel glass-panel" style={{ border: "1px solid #00E6FF", marginBottom: 18, padding: 18 }}>
          <span className="badge badge-success" style={{ marginBottom: 6, fontSize: "0.75rem", fontFamily: "monospace" }}>
            CODE: {classInfo.code}
          </span>
          <h1 style={{ fontSize: "1.4rem", fontWeight: 800, color: "#ffffff", margin: "2px 0 4px" }}>
            {classInfo.subjectName || classInfo.subjectCode}
          </h1>
          <p style={{ color: "#00E6FF", fontWeight: 600, fontSize: "0.85rem", margin: "2px 0 8px" }}>
            Instructor: {classInfo.teacherName || "Faculty"} • {classInfo.subjectCode} ({classInfo.credits ? `${classInfo.credits} Credits` : ""})
          </p>
          <div style={{ display: "flex", gap: 12, color: "#94a3b8", fontSize: "0.8rem", flexWrap: "wrap" }}>
            <span>Dept: {classInfo.department}</span>
            <span>Session: {classInfo.academicSession}</span>
            <span>{classInfo.semester || ""}</span>
          </div>
        </div>
      )}

      {activeSession ? (
        <div className="panel glass-panel" style={{ background: "rgba(0, 255, 136, 0.08)", border: "1px solid #00FF88", marginBottom: 18, padding: 16 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 12 }}>
            <div>
              <span className="badge badge-success" style={{ marginBottom: 4, fontSize: "0.72rem" }}>
                LIVE GPS SESSION ACTIVE
              </span>
              <h3 style={{ color: "#ffffff", fontSize: "1.1rem", fontWeight: 800, margin: "2px 0" }}>
                Teacher is taking attendance now!
              </h3>
              <p style={{ color: "#94a3b8", fontSize: "0.8rem", margin: 0 }}>
                Radius: {activeSession.radiusMeters}m • Ensure GPS is turned ON.
              </p>
            </div>
            <button
              type="button"
              className="btn btn-primary"
              onClick={handleClaimAttendance}
              disabled={claiming}
              style={{ background: "linear-gradient(135deg, #00FF88, #00E6FF)", color: "#000", fontWeight: 900, padding: "10px 18px", fontSize: "0.9rem" }}
            >
              <MapPin size={16} /> {claiming ? "Verifying GPS..." : "Submit Attendance"}
            </button>
          </div>
        </div>
      ) : (
        <div className="panel glass-panel" style={{ border: "1px solid #213042", marginBottom: 18, padding: 14 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 8 }}>
            <span style={{ color: "#94a3b8", fontSize: "0.82rem" }}>No active GPS session at this moment.</span>
            <button type="button" className="btn btn-secondary" onClick={loadData} style={{ fontSize: "0.78rem", padding: "4px 10px" }}>
              <RefreshCw size={13} /> Check Live Session
            </button>
          </div>
        </div>
      )}

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))", gap: 12, marginBottom: 18 }}>
        <div className="panel glass-panel" style={{ border: "1px solid #213042", textAlign: "center", padding: 12 }}>
          <span style={{ color: "#94a3b8", fontSize: "0.72rem", display: "block" }}>TOTAL SESSIONS CONDUCTED</span>
          <span style={{ color: "#ffffff", fontSize: "1.35rem", fontWeight: 900, marginTop: 2, display: "block" }}>
            {totalConducted}
          </span>
        </div>
        <div className="panel glass-panel" style={{ border: "1px solid #213042", textAlign: "center", padding: 12 }}>
          <span style={{ color: "#94a3b8", fontSize: "0.72rem", display: "block" }}>SESSIONS ATTENDED</span>
          <span style={{ color: "#00FF88", fontSize: "1.35rem", fontWeight: 900, marginTop: 2, display: "block" }}>
            {totalAttended}
          </span>
        </div>
        <div className="panel glass-panel" style={{ border: "1px solid #213042", textAlign: "center", padding: 12 }}>
          <span style={{ color: "#94a3b8", fontSize: "0.72rem", display: "block" }}>ATTENDANCE RATE</span>
          <span style={{ color: attendanceRate >= 75 ? "#00FF88" : attendanceRate >= 50 ? "#f59e0b" : "#ef4444", fontSize: "1.35rem", fontWeight: 900, marginTop: 2, display: "block" }}>
            {attendanceRate}%
          </span>
        </div>
      </div>

      <div className="panel glass-panel" style={{ border: "1px solid #213042", padding: 18 }}>
        <h2 style={{ fontSize: "1.1rem", marginBottom: 12 }}>
          <Calendar size={18} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 6 }} /> Class Session Log ({sessionList.length})
        </h2>

        {sessionList.length === 0 ? (
          <div style={{ textAlign: "center", padding: "24px", color: "#94a3b8", fontSize: "0.85rem" }}>
            No attendance sessions have been conducted for this class yet.
          </div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table className="table" style={{ width: "100%", textAlign: "left", fontSize: "0.85rem" }}>
              <thead>
                <tr>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Session Date &amp; Time</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Attendance Status</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Submitted Time / Distance</th>
                </tr>
              </thead>
              <tbody>
                {sessionList.map((s) => {
                  const record = myRecords.find((r) => r.sessionId === s.sessionId);
                  const isPresent = !!record;
                  return (
                    <tr key={s.sessionId} style={{ borderBottom: "1px solid #213042" }}>
                      <td style={{ color: "#ffffff", fontWeight: 600, padding: "10px" }}>
                        <Clock size={13} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 5 }} />
                        {new Date(s.startedAt).toLocaleString()}
                      </td>
                      <td style={{ padding: "10px" }}>
                        {isPresent ? (
                          <span className="badge badge-success" style={{ fontSize: "0.72rem", padding: "3px 8px", display: "inline-flex", alignItems: "center", gap: 4 }}>
                            <CheckCircle2 size={13} /> PRESENT
                          </span>
                        ) : (
                          <span
                            className="badge"
                            style={{
                              fontSize: "0.72rem",
                              padding: "3px 8px",
                              display: "inline-flex",
                              alignItems: "center",
                              gap: 4,
                              background: "rgba(239, 68, 68, 0.15)",
                              color: "#ef4444",
                              border: "1px solid rgba(239, 68, 68, 0.4)",
                            }}
                          >
                            <XCircle size={13} /> ABSENT
                          </span>
                        )}
                      </td>
                      <td style={{ color: isPresent ? "#00FF88" : "#64748b", fontWeight: 600, padding: "10px" }}>
                        {isPresent ? (
                          <>
                            {new Date(record.scannedAt).toLocaleTimeString()}
                            {record.distanceMeters !== undefined && (
                              <span style={{ color: "#94a3b8", fontSize: "0.78rem", marginLeft: 6 }}>
                                ({record.distanceMeters.toFixed(1)}m)
                              </span>
                            )}
                          </>
                        ) : (
                          "Missed"
                        )}
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

