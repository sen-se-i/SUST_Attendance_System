import { useCallback, useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, Clock, MapPin, Users, CheckCircle2 } from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";

export default function TeacherSessionDetailPage() {
  const { classId, sessionId } = useParams();
  const navigate = useNavigate();
  const notify = useToast();

  const [sessionRecords, setSessionRecords] = useState([]);
  const [sessionTime, setSessionTime] = useState(null);

  const loadSessionData = useCallback(async () => {
    try {
      const records = await api(`/api/attendance/classes/${classId}`);
      const filtered = records.filter((r) => r.sessionId === sessionId);
      setSessionRecords(filtered);
      if (filtered.length > 0) {
        setSessionTime(new Date(filtered[0].scannedAt).toLocaleString());
      }
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to load session details", "danger");
    }
  }, [classId, sessionId, notify]);

  useEffect(() => {
    loadSessionData();
  }, [loadSessionData]);

  return (
    <div style={{ paddingBottom: 60 }}>
      {/* Back Button */}
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20 }}>
        <button type="button" className="btn btn-secondary" onClick={() => navigate(`/teacher/class/${classId}`)}>
          <ArrowLeft size={16} /> Back to Class Details
        </button>
      </div>

      {/* Header Info */}
      <div className="panel glass-panel" style={{ border: "1px solid #213042", marginBottom: 24 }}>
        <h1 style={{ fontSize: "1.6rem", fontWeight: 800, color: "#ffffff", marginBottom: 8 }}>
          Session Attendance Details
        </h1>
        <p style={{ color: "#00E6FF", fontWeight: 600 }}>
          <Clock size={16} style={{ verticalAlign: "middle", marginRight: 6 }} />
          Session Time: {sessionTime || "N/A"}
        </p>
        <div style={{ marginTop: 12, display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(0, 255, 136, 0.1)", border: "1px solid rgba(0, 255, 136, 0.3)", padding: "6px 14px", borderRadius: 20, color: "#00FF88", fontWeight: 700 }}>
          <Users size={18} /> {sessionRecords.length} Verified Student(s) Present
        </div>
      </div>

      {/* Verified Attendance List */}
      <div className="panel glass-panel" style={{ border: "1px solid #213042" }}>
        <h2>
          <CheckCircle2 size={20} color="#00FF88" /> Attendance Records
        </h2>

        {sessionRecords.length === 0 ? (
          <div style={{ textAlign: "center", padding: "24px", color: "#94a3b8" }}>No student records found for this session.</div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table className="table" style={{ width: "100%", textAlign: "left" }}>
              <thead>
                <tr>
                  <th>Registration No</th>
                  <th>Scan Time</th>
                  <th>Distance from Teacher</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {sessionRecords.map((r) => (
                  <tr key={r.id} style={{ borderBottom: "1px solid #213042" }}>
                    <td style={{ color: "#ffffff", fontWeight: 700, fontFamily: "monospace", fontSize: "1.05rem" }}>
                      {r.registrationNo}
                    </td>
                    <td style={{ color: "#94a3b8" }}>{new Date(r.scannedAt).toLocaleTimeString()}</td>
                    <td style={{ color: "#00E6FF", fontWeight: 600 }}>
                      <MapPin size={14} style={{ verticalAlign: "middle", marginRight: 4 }} />
                      {r.distanceMeters !== undefined ? `${r.distanceMeters.toFixed(1)}m` : "N/A"}
                    </td>
                    <td>
                      <span className="badge badge-success" style={{ fontSize: "0.75rem" }}>
                        VERIFIED GPS
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
