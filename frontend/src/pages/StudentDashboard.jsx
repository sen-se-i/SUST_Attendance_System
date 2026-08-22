import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Plus, RefreshCw, BookOpen, ChevronRight, Clock, User } from "lucide-react";
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
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20, flexWrap: "wrap", gap: 10 }}>
        <div>
          <h1 style={{ fontSize: "1.4rem", fontWeight: 800, margin: 0 }}>My Enrolled Classes</h1>
          <p style={{ color: "var(--text-secondary)", fontSize: "0.85rem", margin: "4px 0 0" }}>
            Select a class to view attendance records and live GPS sessions.
          </p>
        </div>
        <button type="button" className="btn btn-secondary" style={{ padding: "8px 16px", fontSize: "0.85rem" }} onClick={loadClasses}>
          <RefreshCw size={14} /> Refresh
        </button>
      </div>

      {classes.length === 0 ? (
        <div className="panel glass-panel" style={{ textAlign: "center", padding: "40px 20px" }}>
          <BookOpen size={40} style={{ marginBottom: 12, color: "var(--text-muted)" }} />
          <h3 style={{ fontSize: "1.1rem" }}>No Classes Enrolled Yet</h3>
          <p style={{ color: "var(--text-secondary)", fontSize: "0.88rem", marginBottom: 16 }}>
            Click the "+ JOIN CLASS" button to join your class with a Class Code.
          </p>
        </div>
      ) : (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(290px, 1fr))", gap: 18 }}>
          {classes.map((item) => (
            <div
              key={item.id}
              className="panel glass-panel"
              style={{
                cursor: "pointer",
                padding: "20px",
                transition: "all 0.2s ease",
              }}
              onClick={() => navigate(`/student/class/${item.id}`)}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 10 }}>
                {item.credits ? (
                  <span style={{ fontWeight: 700, fontSize: "0.8rem", color: "var(--text-secondary)" }}>{item.credits} Credits</span>
                ) : <span />}
                <span className="badge badge-success" style={{ fontSize: "0.75rem", fontFamily: "monospace", padding: "3px 8px" }}>
                  CODE: {item.code}
                </span>
              </div>

              <h3 style={{ fontSize: "1.2rem", fontWeight: 700, margin: "0 0 6px" }}>
                {item.subjectName || item.subjectCode}
              </h3>

              <p style={{ color: "var(--text-secondary)", fontSize: "0.85rem", fontWeight: 600, margin: "0 0 6px" }}>
                {item.subjectCode} &nbsp;•&nbsp; {item.academicSession} {item.semester ? `• ${item.semester}` : ""}
              </p>

              <p style={{ color: "var(--text-muted)", fontWeight: 600, fontSize: "0.82rem", margin: "0 0 12px", display: "flex", alignItems: "center", gap: 6 }}>
                <User size={14} /> {item.teacherName || "Faculty"}
              </p>

              <div style={{ background: "var(--bg-surface-elevated)", border: "1px solid var(--border-light)", padding: "8px 12px", borderRadius: "var(--radius-sm)", fontSize: "0.78rem", color: "var(--text-secondary)", display: "flex", alignItems: "center", gap: 6 }}>
                <Clock size={14} />
                <span>
                  Last Session: {item.lastSessionAt ? new Date(item.lastSessionAt).toLocaleString() : "No sessions yet"}
                </span>
              </div>

              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid var(--border-light)", paddingTop: 12, marginTop: 14, fontSize: "0.82rem", color: "var(--text-secondary)" }}>
                <span>{item.department}</span>
                <span style={{ fontWeight: 700, color: "var(--primary)", display: "inline-flex", alignItems: "center", gap: 4 }}>
                  View Attendance Log <ChevronRight size={14} />
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      <div style={{ position: "fixed", bottom: 28, right: 28, zIndex: 9000 }}>
        <button
          type="button"
          className="btn btn-primary"
          style={{
            padding: "12px 24px",
            fontSize: "0.95rem",
            fontWeight: 700,
            borderRadius: "9999px",
            boxShadow: "0 8px 24px rgba(0, 0, 0, 0.2)",
            display: "flex",
            alignItems: "center",
            gap: 8,
          }}
          onClick={() => setShowJoinModal(true)}
        >
          <Plus size={18} /> + JOIN CLASS
        </button>
      </div>

      {showJoinModal && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", backdropFilter: "blur(2px)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
          <div className="panel glass-panel" style={{ width: "min(95vw, 440px)" }}>
            <h2 style={{ fontSize: "1.3rem", fontWeight: 700, marginBottom: 8 }}>Join New Class</h2>
            <p style={{ color: "var(--text-secondary)", fontSize: "0.85rem", marginBottom: 16 }}>
              Enter the Class Code provided by your teacher. Your registration number ({user?.registrationNo || "profile ID"}) will automatically be enrolled.
            </p>

            <form onSubmit={handleJoinClass}>
              <div className="form-group" style={{ marginBottom: 20 }}>
                <label className="form-label">Class Code</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="e.g. SWE301"
                  value={classCode}
                  onChange={(e) => setClassCode(e.target.value.toUpperCase())}
                  style={{ textTransform: "uppercase", letterSpacing: "2px", fontWeight: 700, fontSize: "1.05rem" }}
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


