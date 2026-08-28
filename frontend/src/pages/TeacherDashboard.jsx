import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { RefreshCw, Users, BookOpen, ChevronRight, Clock, UserCheck } from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";

export default function TeacherDashboard() {
  const navigate = useNavigate();
  const notify = useToast();

  const [classes, setClasses] = useState([]);

  const loadClasses = useCallback(async () => {
    try {
      setClasses(await api("/api/classes"));
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to load classes", "danger");
    }
  }, [notify]);

  useEffect(() => {
    loadClasses();
  }, [loadClasses]);

  return (
    <div style={{ paddingBottom: 60 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 18, flexWrap: "wrap", gap: 10 }}>
        <div>
          <h1 style={{ fontSize: "1.4rem", fontWeight: 800, color: "#ffffff", margin: 0 }}>Active Teacher Classes</h1>
          <p style={{ color: "#94a3b8", fontSize: "0.82rem", margin: "2px 0 0" }}>
            Select any class to start live GPS sessions and manage student attendance.
          </p>
        </div>
        <button type="button" className="btn btn-secondary" style={{ padding: "6px 14px", fontSize: "0.82rem" }} onClick={loadClasses}>
          <RefreshCw size={14} /> Refresh
        </button>
      </div>

      {classes.length === 0 ? (
        <div className="panel glass-panel" style={{ textAlign: "center", padding: "36px 18px", border: "1px dashed #213042" }}>
          <BookOpen size={40} color="#3B4D61" style={{ marginBottom: 10 }} />
          <h3 style={{ color: "#ffffff", fontSize: "1.1rem" }}>No Assigned Classes Found</h3>
          <p style={{ color: "#94a3b8", fontSize: "0.85rem", marginBottom: 16 }}>
            Classes assigned to you by the Administrator will appear here.
          </p>
        </div>
      ) : (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 16 }}>
          {classes.map((item) => (
            <div
              key={item.id}
              className="panel glass-panel"
              style={{
                border: "1px solid #213042",
                cursor: "pointer",
                padding: "18px",
                transition: "all 0.2s ease",
              }}
              onClick={() => navigate(`/teacher/class/${item.id}`)}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 }}>
                {item.credits ? (
                  <span style={{ color: "#00FF88", fontWeight: 700, fontSize: "0.8rem" }}>{item.credits} Credits</span>
                ) : <span />}
                <span className="badge badge-success" style={{ fontSize: "0.7rem", fontFamily: "monospace", padding: "2px 6px" }}>
                  CODE: {item.code}
                </span>
              </div>

              <h3 style={{ fontSize: "1.2rem", fontWeight: 800, color: "#ffffff", margin: "0 0 4px" }}>
                {item.subjectName || item.subjectCode}
              </h3>

              <p style={{ color: "#00E6FF", fontSize: "0.82rem", fontWeight: 600, margin: "0 0 12px" }}>
                {item.subjectCode} • {item.academicSession} {item.semester ? `• ${item.semester}` : ""}
              </p>

              <div style={{ display: "flex", justifyContent: "space-between", background: "#090F17", border: "1px solid #213042", padding: "8px 12px", borderRadius: 8, fontSize: "0.78rem", color: "#94a3b8", marginBottom: 12 }}>
                <span>
                  <UserCheck size={14} color="#00FF88" style={{ verticalAlign: "middle", marginRight: 4 }} />
                  {item.enrolledCount || 0} Students
                </span>
                <span>
                  <Clock size={14} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 4 }} />
                  {item.totalSessions || 0} Sessions
                </span>
              </div>

              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid #213042", paddingTop: 10, marginTop: 4, fontSize: "0.78rem", color: "#94a3b8" }}>
                <span>{item.department}</span>
                <span style={{ color: "#00E6FF", fontWeight: 700, display: "inline-flex", alignItems: "center", gap: 4 }}>
                  Manage Class <ChevronRight size={13} />
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
