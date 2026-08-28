import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { RefreshCw, BookOpen, ChevronRight, Clock, User } from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";
import { useAuth } from "../lib/AuthContext";

export default function StudentDashboard() {
  const navigate = useNavigate();
  const notify = useToast();
  const { user } = useAuth();

  const [classes, setClasses] = useState([]);

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

  return (
    <div style={{ paddingBottom: 60 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20, flexWrap: "wrap", gap: 10 }}>
        <div>
          <h1 style={{ fontSize: "1.4rem", fontWeight: 800, margin: 0, color: "#ffffff" }}>My Enrolled Classes</h1>
          <p style={{ color: "#94a3b8", fontSize: "0.85rem", margin: "4px 0 0" }}>
            Student: <strong style={{ color: "#00FF88", fontFamily: "monospace" }}>{user?.registrationNo || user?.email}</strong> • Select a class to scan attendance QR codes and view logs.
          </p>
        </div>
        <button type="button" className="btn btn-secondary" style={{ padding: "8px 16px", fontSize: "0.85rem" }} onClick={loadClasses}>
          <RefreshCw size={14} /> Refresh
        </button>
      </div>

      {classes.length === 0 ? (
        <div className="panel glass-panel" style={{ textAlign: "center", padding: "40px 20px" }}>
          <BookOpen size={40} style={{ marginBottom: 12, color: "#3B4D61" }} />
          <h3 style={{ fontSize: "1.1rem", color: "#ffffff" }}>No Classes Enrolled Yet</h3>
          <p style={{ color: "#94a3b8", fontSize: "0.88rem", maxWidth: 450, margin: "0 auto" }}>
            Your department administrator automatically enrolls your registration number when course classes are created.
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
                  <span style={{ fontWeight: 700, fontSize: "0.8rem", color: "#00FF88" }}>{item.credits} Credits</span>
                ) : <span />}
                <span className="badge badge-success" style={{ fontSize: "0.75rem", fontFamily: "monospace", padding: "3px 8px" }}>
                  CODE: {item.code}
                </span>
              </div>

              <h3 style={{ fontSize: "1.2rem", fontWeight: 700, margin: "0 0 6px", color: "#ffffff" }}>
                {item.subjectName || item.subjectCode}
              </h3>

              <p style={{ color: "#00E6FF", fontSize: "0.85rem", fontWeight: 600, margin: "0 0 6px" }}>
                {item.subjectCode} • {item.academicSession} {item.semester ? `• ${item.semester}` : ""}
              </p>

              <p style={{ color: "#94a3b8", fontWeight: 600, fontSize: "0.82rem", margin: "0 0 12px", display: "flex", alignItems: "center", gap: 6 }}>
                <User size={14} color="#00E6FF" /> {item.teacherName || "Faculty"}
              </p>

              <div style={{ background: "#090F17", border: "1px solid #213042", padding: "8px 12px", borderRadius: 8, fontSize: "0.78rem", color: "#94a3b8", display: "flex", alignItems: "center", gap: 6 }}>
                <Clock size={14} color="#00E6FF" />
                <span>
                  Last Session: {item.lastSessionAt ? new Date(item.lastSessionAt).toLocaleString() : "No sessions yet"}
                </span>
              </div>

              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid #213042", paddingTop: 12, marginTop: 14, fontSize: "0.82rem", color: "#94a3b8" }}>
                <span>{item.department}</span>
                <span style={{ fontWeight: 700, color: "#00E6FF", display: "inline-flex", alignItems: "center", gap: 4 }}>
                  View Attendance Log <ChevronRight size={14} />
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
