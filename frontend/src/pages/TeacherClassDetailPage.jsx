import { useCallback, useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  ArrowLeft,
  Calendar,
  Clock,
  MapPin,
  RefreshCw,
  Smartphone,
  KeyRound,
  Trash2,
  Users,
  AlertTriangle,
  ChevronRight,
  Square,
  Play,
  CheckCircle2,
} from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";
import { SessionPanel } from "../components/SessionPanel";

export default function TeacherClassDetailPage() {
  const { classId } = useParams();
  const navigate = useNavigate();
  const notify = useToast();

  const [classInfo, setClassInfo] = useState(null);
  const [historySessions, setHistorySessions] = useState([]);
  const [enrolledStudents, setEnrolledStudents] = useState([]);
  const [attendanceRecords, setAttendanceRecords] = useState([]);
  const [activeSession, setActiveSession] = useState(null);
  const [busy, setBusy] = useState(false);

  const [selectedStudent, setSelectedStudent] = useState(null);
  const [studentHistory, setStudentHistory] = useState([]);
  const [showAdvance, setShowAdvance] = useState(false);
  const [selectedRecordIds, setSelectedRecordIds] = useState([]);
  const [confirmModal, setConfirmModal] = useState({ open: false, type: null, data: null });
  const [deleteSessionModal, setDeleteSessionModal] = useState({ open: false, sessionId: null });

  const loadData = useCallback(async () => {
    try {
      const classes = await api("/api/classes");
      const found = classes.find((c) => c.id === classId);
      if (found) setClassInfo(found);

      const students = await api(`/api/classes/${classId}/students`);
      setEnrolledStudents(students);

      const records = await api(`/api/attendance/classes/${classId}`);
      setAttendanceRecords(records);

      const sessions = await api(`/api/sessions/class/${classId}`);
      setHistorySessions(sessions);
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to load class details", "danger");
    }
  }, [classId, notify]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  async function handleStartSession(params) {
    setBusy(true);
    try {
      const started = await api("/api/sessions/start", {
        method: "POST",
        body: JSON.stringify({
          classId,
          latitude: params.latitude,
          longitude: params.longitude,
          accuracyMeters: params.accuracyMeters,
          capturedAt: params.capturedAt,
          radiusMeters: params.radiusMeters || 20.0,
          totalTicks: 150,
          intervalSeconds: 1,
        }),
      });
      setActiveSession(started);
      notify("GPS Session started", "success");
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to start session", "danger");
    } finally {
      setBusy(false);
    }
  }

  async function handleStopSession() {
    if (!activeSession) return;
    setBusy(true);
    try {
      await api(`/api/sessions/${activeSession.sessionId}/stop`, { method: "POST" });
      setActiveSession(null);
      await loadData();
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to stop session", "danger");
    } finally {
      setBusy(false);
    }
  }

  async function openStudentModal(student) {
    setSelectedStudent(student);
    setShowAdvance(false);
    setSelectedRecordIds([]);
    try {
      const records = await api(`/api/attendance/classes/${classId}`);
      const studentRecs = records.filter((r) => r.registrationNo === student.registrationNo);
      setStudentHistory(studentRecs);
    } catch {
      setStudentHistory([]);
    }
  }

  async function handleResetDevice() {
    if (!selectedStudent) return;
    setBusy(true);
    try {
      await api(`/api/attendance/students/${selectedStudent.studentId || selectedStudent.registrationNo}/reset-device`, { method: "POST" });
      notify(`Device ID reset for student ${selectedStudent.registrationNo}`, "success");
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to reset device", "danger");
    } finally {
      setBusy(false);
    }
  }

  function confirmDeleteFullHistory() {
    setConfirmModal({
      open: true,
      type: "FULL",
      title: "Delete Full Attendance History?",
      message: `Are you sure you want to delete ALL attendance records for student ${selectedStudent.registrationNo} in this class? This action CANNOT be undone!`,
    });
  }

  function confirmDeleteSelectedHistory() {
    if (!selectedRecordIds.length) {
      notify("Please select at least one attendance record to delete", "danger");
      return;
    }
    setConfirmModal({
      open: true,
      type: "BATCH",
      title: `Delete ${selectedRecordIds.length} Selected Record(s)?`,
      message: `Are you sure you want to permanently delete the selected ${selectedRecordIds.length} attendance record(s)? This action CANNOT be undone!`,
    });
  }

  function confirmRemoveStudent(student) {
    setConfirmModal({
      open: true,
      type: "REMOVE_STUDENT",
      data: student,
      title: `Remove ${student.registrationNo} from Class?`,
      message: `Are you sure you want to remove student ${student.registrationNo} from this class? They will no longer be able to submit attendance for this class, and their attendance history in this class will be deleted.`,
    });
  }

  async function executeDeletion() {
    setBusy(true);
    try {
      if (confirmModal.type === "REMOVE_STUDENT") {
        await api(`/api/classes/${classId}/students/${confirmModal.data.registrationNo}`, { method: "DELETE" });
        notify(`Student ${confirmModal.data.registrationNo} removed from class`, "success");
      } else if (confirmModal.type === "FULL") {
        await api(`/api/attendance/classes/${classId}/students/${selectedStudent.studentId || selectedStudent.registrationNo}`, { method: "DELETE" });
        notify(`All attendance history deleted for ${selectedStudent.registrationNo}`, "success");
      } else if (confirmModal.type === "BATCH") {
        await api("/api/attendance/records/batch-delete", {
          method: "POST",
          body: JSON.stringify(selectedRecordIds),
        });
        notify(`Deleted ${selectedRecordIds.length} attendance record(s)`, "success");
      }
      setConfirmModal({ open: false, type: null, data: null });
      setSelectedStudent(null);
      await loadData();
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Action failed", "danger");
    } finally {
      setBusy(false);
    }
  }

  function toggleRecordSelect(id) {
    setSelectedRecordIds((prev) => (prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]));
  }

  return (
    <div style={{ paddingBottom: 60 }}>

      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
        <button type="button" className="btn btn-secondary" style={{ padding: "6px 14px", fontSize: "0.85rem" }} onClick={() => navigate("/teacher")}>
          <ArrowLeft size={15} /> Back to Dashboard
        </button>
      </div>

      {classInfo && (
        <div className="panel glass-panel" style={{ border: "1px solid #213042", marginBottom: 20, padding: 18 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", flexWrap: "wrap", gap: 12 }}>
            <div>
              <span className="badge badge-success" style={{ marginBottom: 6, fontSize: "0.75rem", fontFamily: "monospace" }}>
                CODE: {classInfo.code}
              </span>
              <h1 style={{ fontSize: "1.4rem", fontWeight: 800, color: "#ffffff", margin: "2px 0 4px" }}>
                {classInfo.subjectName || classInfo.subjectCode}
              </h1>
              <p style={{ color: "#00E6FF", fontWeight: 600, fontSize: "0.85rem", margin: 0 }}>
                {classInfo.subjectCode} • {classInfo.department} • {classInfo.academicSession} {classInfo.semester ? `• ${classInfo.semester}` : ""}
              </p>
            </div>
            {classInfo.credits && (
              <div style={{ background: "rgba(0, 230, 255, 0.1)", border: "1px solid #213042", padding: "6px 12px", borderRadius: 8, textAlign: "center" }}>
                <span style={{ color: "#94a3b8", fontSize: "0.7rem", display: "block" }}>CREDITS</span>
                <span style={{ color: "#00FF88", fontSize: "1.15rem", fontWeight: 800 }}>{classInfo.credits}</span>
              </div>
            )}
          </div>
        </div>
      )}

      <SessionPanel
        session={activeSession}
        busy={busy}
        onStart={handleStartSession}
        onStop={handleStopSession}
        onFinished={handleStopSession}
      />

      <div className="panel glass-panel" style={{ marginTop: 20, border: "1px solid #213042", padding: 18 }}>
        <h2 style={{ fontSize: "1.15rem", marginBottom: 4 }}>
          <Calendar size={18} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 6 }} /> Class Session History
        </h2>
        <p style={{ color: "#94a3b8", fontSize: "0.8rem", marginBottom: 14 }}>
          Past sessions conducted. Click "View Logs" to see student attendance or delete the session.
        </p>

        {historySessions.length === 0 ? (
          <div style={{ textAlign: "center", padding: "20px", color: "#94a3b8", fontSize: "0.85rem" }}>No sessions conducted yet.</div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table className="table" style={{ width: "100%", textAlign: "left", fontSize: "0.85rem" }}>
              <thead>
                <tr>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Session Date &amp; Time</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Status</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Verified Students</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {historySessions.map((s) => {
                  const isEmpty = s.attendanceCount === 0;
                  return (
                    <tr key={s.sessionId} style={{ borderBottom: "1px solid #213042" }}>
                      <td style={{ color: "#ffffff", fontWeight: 600, padding: "10px" }}>
                        <Clock size={13} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 5 }} />
                        {new Date(s.startedAt).toLocaleString()}
                      </td>
                      <td style={{ padding: "10px" }}>
                        <span
                          className={`badge ${s.status === "ENDED" ? "badge-secondary" : "badge-success"}`}
                          style={{ fontSize: "0.7rem", padding: "2px 7px" }}
                        >
                          {s.status}
                        </span>
                      </td>
                      <td style={{ color: isEmpty ? "#ef4444" : "#00FF88", fontWeight: 700, padding: "10px" }}>
                        {isEmpty ? "0 — No attendance" : `${s.attendanceCount} Student(s)`}
                      </td>
                      <td style={{ padding: "10px" }}>
                        <button
                          type="button"
                          className="btn btn-secondary"
                          style={{ padding: "4px 12px", fontSize: "0.8rem", display: "inline-flex", alignItems: "center", gap: 4 }}
                          onClick={() => navigate(`/teacher/class/${classId}/session/${s.sessionId}`)}
                        >
                          View Logs <ChevronRight size={13} />
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="panel glass-panel" style={{ marginTop: 20, border: "1px solid #213042", padding: 18 }}>
        <h2 style={{ fontSize: "1.15rem", marginBottom: 12 }}>
          <Users size={18} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 6 }} /> Active Students ({enrolledStudents.length})
        </h2>

        {enrolledStudents.length === 0 ? (
          <div style={{ textAlign: "center", padding: "24px", color: "#94a3b8", fontSize: "0.85rem" }}>
            <Users size={28} style={{ opacity: 0.3, marginBottom: 8 }} />
            <p style={{ margin: 0 }}>No students have joined yet.</p>
            <p style={{ margin: "4px 0 0", fontSize: "0.78rem" }}>Share the class code with students so they can join.</p>
          </div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table className="table" style={{ width: "100%", textAlign: "left", fontSize: "0.85rem" }}>
              <thead>
                <tr>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>#</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Registration No</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Status</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Joined At</th>
                  <th style={{ padding: "8px 10px", fontSize: "0.8rem" }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {enrolledStudents.map((s, idx) => (
                  <tr key={s.registrationNo} style={{ borderBottom: "1px solid #213042" }}>
                    <td style={{ color: "#94a3b8", fontSize: "0.8rem", padding: "8px 10px" }}>{idx + 1}</td>
                    <td style={{ color: "#ffffff", fontWeight: 700, fontFamily: "monospace", fontSize: "0.9rem", padding: "8px 10px" }}>{s.registrationNo}</td>
                    <td style={{ padding: "8px 10px" }}>
                      <span className="badge badge-success" style={{ fontSize: "0.7rem", padding: "2px 6px" }}>Active</span>
                    </td>
                    <td style={{ color: "#94a3b8", fontSize: "0.78rem", padding: "8px 10px" }}>
                      {s.joinedAt ? new Date(s.joinedAt).toLocaleDateString() : "—"}
                    </td>
                    <td style={{ padding: "8px 10px" }}>
                      <div style={{ display: "flex", gap: 6 }}>
                        <button
                          type="button"
                          className="btn btn-secondary"
                          style={{ padding: "3px 10px", fontSize: "0.75rem", color: "#00E6FF" }}
                          onClick={() => openStudentModal(s)}
                        >
                          Manage
                        </button>
                        <button
                          type="button"
                          className="btn btn-danger"
                          style={{ padding: "3px 8px", fontSize: "0.75rem", display: "inline-flex", alignItems: "center", gap: 3 }}
                          onClick={() => confirmRemoveStudent(s)}
                          disabled={busy}
                        >
                          <Trash2 size={12} /> Remove
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selectedStudent && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.85)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: 14 }}>
          <div className="panel glass-panel" style={{ width: "min(95vw, 620px)", maxHeight: "90vh", overflowY: "auto", border: "1px solid #00E6FF", padding: 20 }}>
            <div style={{ borderBottom: "1px solid #213042", paddingBottom: 10, marginBottom: 14 }}>

              <h2 style={{ fontSize: "1.4rem", fontWeight: 900, color: "#00E6FF", margin: 0, letterSpacing: "0.5px" }}>
                {selectedStudent.registrationNo}
              </h2>
              <p style={{ color: "#94a3b8", fontSize: "0.75rem", margin: "2px 0 0" }}>CLASS ID: {classId}</p>
            </div>

            <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginBottom: 16 }}>
              <button type="button" className="btn btn-secondary" style={{ padding: "6px 12px", fontSize: "0.8rem", color: "#00FF88", borderColor: "rgba(0, 255, 136, 0.4)" }} onClick={handleResetDevice} disabled={busy}>
                <Smartphone size={14} /> Reset Device
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                style={{ padding: "6px 12px", fontSize: "0.8rem", color: "#00E6FF", borderColor: "rgba(0, 230, 255, 0.4)" }}
                onClick={async () => {
                  const newPass = prompt(`Enter new password for student ${selectedStudent.registrationNo}:`, "123456");
                  if (!newPass || !newPass.trim()) return;
                  setBusy(true);
                  try {
                    await api("/api/auth/reset-password", {
                      method: "POST",
                      body: JSON.stringify({ registrationNo: selectedStudent.registrationNo, newPassword: newPass.trim() }),
                    });
                    notify(`Password reset to "${newPass.trim()}" for student ${selectedStudent.registrationNo}`, "success");
                  } catch (error) {
                    notify(error instanceof ApiError ? error.message : "Failed to reset password", "danger");
                  } finally {
                    setBusy(false);
                  }
                }}
                disabled={busy}
              >
                <KeyRound size={14} /> Reset Password
              </button>
              <button
                type="button"
                className="btn btn-danger"
                style={{ padding: "6px 12px", fontSize: "0.8rem", display: "inline-flex", alignItems: "center", gap: 4 }}
                onClick={() => confirmRemoveStudent(selectedStudent)}
                disabled={busy}
              >
                <Trash2 size={14} /> Remove Student
              </button>
              <button
                type="button"
                className={`btn ${showAdvance ? "btn-danger" : "btn-secondary"}`}
                style={{ marginLeft: "auto", padding: "6px 12px", fontSize: "0.8rem" }}
                onClick={() => setShowAdvance(!showAdvance)}
              >
                {showAdvance ? "Hide Advanced" : "Advanced"}
              </button>
            </div>

            {showAdvance && (
              <div style={{ background: "rgba(239, 68, 68, 0.08)", border: "1px solid rgba(239, 68, 68, 0.3)", borderRadius: 10, padding: 14, marginBottom: 16 }}>
                <h4 style={{ color: "#ef4444", margin: "0 0 6px", fontSize: "0.9rem", display: "flex", alignItems: "center", gap: 6 }}>
                  <AlertTriangle size={16} /> Danger Zone Deletion Controls
                </h4>
                <p style={{ color: "#cbd5e1", fontSize: "0.8rem", marginBottom: 10 }}>
                  Deleting history will permanently remove attendance records for this student.
                </p>
                <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                  <button
                    type="button"
                    className="btn"
                    style={{ background: "linear-gradient(135deg, #ef4444, #dc2626)", color: "#ffffff", fontWeight: 700, padding: "6px 12px", fontSize: "0.8rem" }}
                    onClick={confirmDeleteFullHistory}
                    disabled={busy}
                  >
                    <Trash2 size={14} /> Delete FULL Attendance History
                  </button>
                  {selectedRecordIds.length > 0 && (
                    <button
                      type="button"
                      className="btn"
                      style={{ background: "linear-gradient(135deg, #ef4444, #dc2626)", color: "#ffffff", fontWeight: 700, padding: "6px 12px", fontSize: "0.8rem" }}
                      onClick={confirmDeleteSelectedHistory}
                      disabled={busy}
                    >
                      <Trash2 size={14} /> Delete Selected ({selectedRecordIds.length}) Records
                    </button>
                  )}
                </div>
              </div>
            )}

            <h4 style={{ color: "#ffffff", marginBottom: 10, fontSize: "0.95rem" }}>Student Attendance History</h4>
            {studentHistory.length === 0 ? (
              <div style={{ textAlign: "center", padding: "16px", color: "#94a3b8", fontSize: "0.82rem" }}>No attendance recorded for this student in this class.</div>
            ) : (
              <div style={{ overflowX: "auto" }}>
                <table className="table" style={{ width: "100%", textAlign: "left", fontSize: "0.82rem" }}>
                  <thead>
                    <tr>
                      {showAdvance && <th style={{ padding: "6px 8px" }}>Select</th>}
                      <th style={{ padding: "6px 8px" }}>Date</th>
                      <th style={{ padding: "6px 8px" }}>Time</th>
                      <th style={{ padding: "6px 8px" }}>Device ID</th>
                    </tr>
                  </thead>
                  <tbody>
                    {studentHistory.map((h) => {
                      const d = new Date(h.scannedAt);
                      const isSelected = selectedRecordIds.includes(h.id);
                      return (
                        <tr key={h.id} style={{ borderBottom: "1px solid #213042", background: isSelected ? "rgba(239, 68, 68, 0.12)" : "transparent" }}>
                          {showAdvance && (
                            <td style={{ padding: "6px 8px" }}>
                              <input
                                type="checkbox"
                                checked={isSelected}
                                onChange={() => toggleRecordSelect(h.id)}
                                style={{ width: 16, height: 16, accentColor: "#ef4444" }}
                              />
                            </td>
                          )}
                          <td style={{ color: "#ffffff", padding: "6px 8px" }}>{d.toLocaleDateString()}</td>
                          <td style={{ color: "#00FF88", fontWeight: 600, padding: "6px 8px" }}>{d.toLocaleTimeString()}</td>
                          <td style={{ fontFamily: "monospace", fontSize: "0.75rem", color: "#94a3b8", padding: "6px 8px" }}>
                            {h.deviceInstallId ? h.deviceInstallId.slice(0, 14) + "..." : "Web/N/A"}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}

            <div style={{ textAlign: "right", marginTop: 16 }}>
              <button type="button" className="btn btn-secondary" style={{ padding: "6px 16px", fontSize: "0.85rem" }} onClick={() => setSelectedStudent(null)}>
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {confirmModal.open && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.9)", zIndex: 10000, display: "flex", alignItems: "center", justifyContent: "center", padding: 14 }}>
          <div className="panel glass-panel" style={{ width: "min(90vw, 420px)", border: "2px solid #ef4444", textAlign: "center", padding: 22 }}>
            <AlertTriangle size={40} color="#ef4444" style={{ margin: "0 auto 10px" }} />
            <h3 style={{ color: "#ef4444", fontSize: "1.15rem", fontWeight: 800, margin: "0 0 8px" }}>{confirmModal.title}</h3>
            <p style={{ color: "#e2e8f0", fontSize: "0.85rem", margin: "8px 0 20px", lineHeight: 1.5 }}>{confirmModal.message}</p>
            <div style={{ display: "flex", gap: 10, justifyContent: "center" }}>
              <button type="button" className="btn btn-secondary" style={{ padding: "8px 16px", fontSize: "0.85rem" }} onClick={() => setConfirmModal({ open: false, type: null, data: null })}>
                Cancel
              </button>
              <button
                type="button"
                className="btn"
                style={{ background: "linear-gradient(135deg, #ef4444, #dc2626)", color: "#ffffff", fontWeight: 700, padding: "8px 16px", fontSize: "0.85rem" }}
                onClick={executeDeletion}
                disabled={busy}
              >
                {confirmModal.type === "REMOVE_STUDENT" ? "Yes, Remove Student" : "Yes, Delete"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

