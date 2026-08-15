import { useCallback, useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, Clock, MapPin, Users, CheckCircle2, Trash2 } from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";

export default function TeacherSessionDetailPage() {
  const { classId, sessionId } = useParams();
  const navigate = useNavigate();
  const notify = useToast();

  const [sessionRecords, setSessionRecords] = useState([]);
  const [sessionTime, setSessionTime] = useState(null);
  const [busy, setBusy] = useState(false);
  const [deleteModal, setDeleteModal] = useState(false);

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

  async function handleDeleteSession() {
    setBusy(true);
    try {
      await api(`/api/sessions/${sessionId}`, { method: "DELETE" });
      notify("Session and all its attendance records have been deleted.", "success");
      setDeleteModal(false);
      navigate(`/teacher/class/${classId}`);
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to delete session", "danger");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ paddingBottom: 60 }}>
      {/* Back Button and Delete Button Toolbar */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 10, marginBottom: 16 }}>
        <button type="button" className="btn btn-secondary" style={{ padding: "6px 14px", fontSize: "0.85rem" }} onClick={() => navigate(`/teacher/class/${classId}`)}>
          <ArrowLeft size={15} /> Back to Class
        </button>
        <button
          type="button"
          className="btn btn-danger"
          style={{ padding: "6px 14px", fontSize: "0.85rem", display: "inline-flex", alignItems: "center", gap: 6 }}
          onClick={() => setDeleteModal(true)}
          disabled={busy}
        >
          <Trash2 size={15} /> Delete Session
        </button>
      </div>

      {/* Header Info */}
      <div className="panel glass-panel" style={{ border: "1px solid #213042", marginBottom: 20, padding: 18 }}>
        <h1 style={{ fontSize: "1.35rem", fontWeight: 800, color: "#ffffff", marginBottom: 6 }}>
          Session Attendance Logs
        </h1>
        <p style={{ color: "#00E6FF", fontWeight: 600, fontSize: "0.85rem", margin: "0 0 10px" }}>
          <Clock size={14} style={{ verticalAlign: "middle", marginRight: 6 }} />
          Session Time: {sessionTime || "Conducted Session"}
        </p>
        <div style={{ display: "inline-flex", alignItems: "center", gap: 6, background: "rgba(0, 255, 136, 0.1)", border: "1px solid rgba(0, 255, 136, 0.3)", padding: "4px 12px", borderRadius: 16, color: "#00FF88", fontWeight: 700, fontSize: "0.82rem" }}>
          <Users size={15} /> {sessionRecords.length} Student(s) Present
        </div>
      </div>

      {/* Verified Attendance List */}
      <div className="panel glass-panel" style={{ border: "1px solid #213042", padding: 18 }}>
        <h2 style={{ fontSize: "1.1rem", marginBottom: 14 }}>
          <CheckCircle2 size={18} color="#00FF88" style={{ verticalAlign: "middle", marginRight: 6 }} /> Attendance Records ({sessionRecords.length})
        </h2>

        {sessionRecords.length === 0 ? (
          <div style={{ textAlign: "center", padding: "20px", color: "#94a3b8", fontSize: "0.85rem" }}>
            No student attendance records recorded for this session.
          </div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table className="table" style={{ width: "100%", textAlign: "left", fontSize: "0.85rem" }}>
              <thead>
                <tr>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Registration No</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Scan Time</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>GPS Distance</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Status</th>
                </tr>
              </thead>
              <tbody>
                {sessionRecords.map((r) => (
                  <tr key={r.id} style={{ borderBottom: "1px solid #213042" }}>
                    <td style={{ color: "#ffffff", fontWeight: 700, fontFamily: "monospace", padding: "10px", fontSize: "0.95rem" }}>
                      {r.registrationNo}
                    </td>
                    <td style={{ color: "#94a3b8", padding: "10px" }}>{new Date(r.scannedAt).toLocaleTimeString()}</td>
                    <td style={{ color: "#00E6FF", fontWeight: 600, padding: "10px" }}>
                      <MapPin size={13} style={{ verticalAlign: "middle", marginRight: 3 }} />
                      {r.distanceMeters !== undefined ? `${r.distanceMeters.toFixed(1)}m` : "N/A"}
                    </td>
                    <td style={{ padding: "10px" }}>
                      <span className="badge badge-success" style={{ fontSize: "0.72rem", padding: "3px 8px" }}>
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

      {/* Delete Confirmation Modal */}
      {deleteModal && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.8)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
          <div className="panel glass-panel" style={{ maxWidth: 400, width: "100%", border: "1px solid #ef4444", padding: 24 }}>
            <h3 style={{ color: "#ef4444", margin: "0 0 10px", fontSize: "1.15rem", display: "flex", alignItems: "center", gap: 8 }}>
              <Trash2 size={18} /> Delete This Session?
            </h3>
            <p style={{ color: "#94a3b8", fontSize: "0.85rem", lineHeight: 1.5, margin: "0 0 20px" }}>
              Are you sure you want to delete this session? This will permanently delete this session record and <strong style={{ color: "#ffffff" }}>all attendance logs</strong> associated with it.
            </p>
            <div style={{ display: "flex", gap: 10 }}>
              <button
                type="button"
                className="btn btn-danger"
                style={{ flex: 1, padding: "8px 12px", fontSize: "0.85rem" }}
                disabled={busy}
                onClick={handleDeleteSession}
              >
                {busy ? "Deleting..." : "Yes, Delete"}
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                style={{ flex: 1, padding: "8px 12px", fontSize: "0.85rem" }}
                onClick={() => setDeleteModal(false)}
                disabled={busy}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
