import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Plus, RefreshCw, BookOpen, ChevronRight, Clock, User, CheckCircle2 } from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";
import { useAuth } from "../lib/AuthContext";

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

  return (
    <div style={{ paddingBottom: 100 }}>
      {/* Header Bar */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
        <div>
          <h1 style={{ fontSize: "1.8rem", fontWeight: 800, color: "#ffffff", margin: 0 }}>My Enrolled Classes</h1>
          <p style={{ color: "#94a3b8", fontSize: "0.9rem", margin: "4px 0 0" }}>
            Select a class to view attendance records and live GPS sessions.
          </p>
        </div>
        <button type="button" className="btn btn-secondary" onClick={loadClasses}>
          <RefreshCw size={16} /> Refresh
        </button>
      </div>

      {/* Enrolled Classes Grid */}
      {classes.length === 0 ? (
        <div className="panel glass-panel" style={{ textAlign: "center", padding: "48px 24px", border: "1px dashed #213042" }}>
          <BookOpen size={48} color="#3B4D61" style={{ marginBottom: 12 }} />
          <h3 style={{ color: "#ffffff" }}>No Classes Enrolled Yet</h3>
          <p style={{ color: "#94a3b8", fontSize: "0.9rem", marginBottom: 20 }}>
            Click the "+ JOIN CLASS" button at the bottom to join your first class with a Class Code.
          </p>
        </div>
      ) : (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: 20 }}>
          {classes.map((item) => (
            <div
              key={item.id}
              className="panel glass-panel"
              style={{
                border: "1px solid #213042",
                cursor: "pointer",
                transition: "all 0.2s ease",
              }}
              onClick={() => navigate(`/student/class/${item.id}`)}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 10 }}>
                {item.credits ? (
                  <span style={{ color: "#00FF88", fontWeight: 700, fontSize: "0.85rem" }}>{item.credits} Credits</span>
                ) : <span />}
                <span className="badge badge-success" style={{ fontSize: "0.72rem", fontFamily: "monospace" }}>
                  CODE: {item.code}
                </span>
              </div>

              {/* Subject Name — primary, large */}
              <h3 style={{ fontSize: "1.35rem", fontWeight: 800, color: "#ffffff", margin: "0 0 4px" }}>
                {item.subjectName || item.subjectCode}
              </h3>

              {/* Subject Code + Session — secondary */}
              <p style={{ color: "#00E6FF", fontSize: "0.85rem", fontWeight: 600, margin: "0 0 6px" }}>
                {item.subjectCode} &nbsp;•&nbsp; {item.academicSession} {item.semester ? `• ${item.semester}` : ""}
              </p>

              {/* Teacher Name */}
              <p style={{ color: "#94a3b8", fontWeight: 600, fontSize: "0.85rem", margin: "0 0 12px", display: "flex", alignItems: "center", gap: 6 }}>
                <User size={13} /> {item.teacherName || "Faculty"}
              </p>

              {/* Last Session Date */}
              <div style={{ background: "rgba(0, 230, 255, 0.06)", border: "1px solid #213042", padding: "8px 12px", borderRadius: 8, fontSize: "0.8rem", color: "#94a3b8", display: "flex", alignItems: "center", gap: 6 }}>
                <Clock size={14} color="#00E6FF" />
                <span>
                  Last Session: {item.lastSessionAt ? new Date(item.lastSessionAt).toLocaleString() : "No sessions yet"}
                </span>
              </div>

              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid #213042", paddingTop: 12, marginTop: 14, fontSize: "0.8rem", color: "#94a3b8" }}>
                <span>{item.department}</span>
                <span style={{ color: "#00E6FF", fontWeight: 700, display: "inline-flex", alignItems: "center", gap: 4 }}>
                  View Attendance Log <ChevronRight size={14} />
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Floating Bottom "+ JOIN CLASS" Button */}
      <div style={{ position: "fixed", bottom: 24, right: 24, zIndex: 9000 }}>
        <button
          type="button"
          className="btn btn-primary"
          style={{
            padding: "14px 28px",
            fontSize: "1.05rem",
            fontWeight: 800,
            borderRadius: 30,
            boxShadow: "0 8px 32px rgba(0, 230, 255, 0.4)",
            display: "flex",
            alignItems: "center",
            gap: 8,
            background: "linear-gradient(135deg, #00E6FF, #00FF88)",
            color: "#000000",
          }}
          onClick={() => setShowJoinModal(true)}
        >
          <Plus size={20} /> + JOIN CLASS
        </button>
      </div>

      {/* Join Class Modal */}
      {showJoinModal && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.85)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
          <div className="panel glass-panel" style={{ width: "min(95vw, 440px)", border: "1px solid #00E6FF" }}>
            <h2 style={{ fontSize: "1.4rem", fontWeight: 800, color: "#ffffff", marginBottom: 8 }}>Join New Class</h2>
            <p style={{ color: "#94a3b8", fontSize: "0.85rem", marginBottom: 16 }}>
              Enter the 6-character Class Code provided by your teacher. Your registration number ({user.registrationNo || "profile ID"}) will automatically be registered.
            </p>

            <form onSubmit={handleJoinClass}>
              <div className="form-group" style={{ marginBottom: 20 }}>
                <label className="form-label">Class Code</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="e.g. SWE301 or Class Code"
                  value={classCode}
                  onChange={(e) => setClassCode(e.target.value.toUpperCase())}
                  style={{ textTransform: "uppercase", letterSpacing: "2px", fontWeight: 700, fontSize: "1.1rem" }}
                  maxLength={20}
                  required
                />
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
