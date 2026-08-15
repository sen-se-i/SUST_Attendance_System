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

  // Student Control Modal State
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [studentHistory, setStudentHistory] = useState([]);
  const [showAdvance, setShowAdvance] = useState(false);
  const [selectedRecordIds, setSelectedRecordIds] = useState([]);
  const [confirmModal, setConfirmModal] = useState({ open: false, type: null, data: null });

  const loadData = useCallback(async () => {
    try {
      const classes = await api("/api/classes");
      const found = classes.find((c) => c.id === classId);
      if (found) setClassInfo(found);

      const students = await api(`/api/classes/${classId}/students`);
      setEnrolledStudents(students);

      const records = await api(`/api/attendance/classes/${classId}`);
      setAttendanceRecords(records);

      // Group records into sessions history
      const sessionMap = new Map();
      records.forEach((r) => {
        if (!sessionMap.has(r.sessionId)) {
          sessionMap.set(r.sessionId, {
            sessionId: r.sessionId,
            scannedAt: r.scannedAt,
            count: 0,
          });
        }
        sessionMap.get(r.sessionId).count++;
      });
      setHistorySessions(Array.from(sessionMap.values()));
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


  // Open Student Control Modal
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

  // Action: Reset Device ID
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

  // Delete Full History Confirm
  function confirmDeleteFullHistory() {
    setConfirmModal({
      open: true,
      type: "FULL",
      title: "Delete Full Attendance History?",
      message: `Are you sure you want to delete ALL attendance records for student ${selectedStudent.registrationNo} in this class? This action CANNOT be undone!`,
    });
  }

  // Delete Selected History Confirm
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

  async function executeDeletion() {
    setBusy(true);
    try {
      if (confirmModal.type === "FULL") {
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
      notify(error instanceof ApiError ? error.message : "Failed to delete attendance records", "danger");
    } finally {
      setBusy(false);
    }
  }

  function toggleRecordSelect(id) {
    setSelectedRecordIds((prev) => (prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]));
  }

  return (
    <div style={{ paddingBottom: 60 }}>
      {/* Back to Dashboard Bar */}
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20 }}>
        <button type="button" className="btn btn-secondary" onClick={() => navigate("/teacher")}>
          <ArrowLeft size={16} /> Back to Dashboard
        </button>
      </div>

      {/* Class Header Card */}
      {classInfo && (
        <div className="panel glass-panel" style={{ border: "1px solid #213042", marginBottom: 24 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", flexWrap: "wrap", gap: 16 }}>
            <div>
              <span className="badge badge-success" style={{ marginBottom: 8, fontSize: "0.8rem" }}>
                CODE: {classInfo.code}
              </span>
              <h1 style={{ fontSize: "1.8rem", fontWeight: 800, color: "#ffffff", margin: "4px 0" }}>
                {classInfo.subjectName || classInfo.subjectCode}
              </h1>
              <p style={{ color: "#00E6FF", fontWeight: 600, fontSize: "0.95rem" }}>
                {classInfo.department} • {classInfo.academicSession} • {classInfo.semester || "Semester N/A"}
              </p>
            </div>
            {classInfo.credits && (
              <div style={{ background: "rgba(0, 230, 255, 0.1)", border: "1px solid #213042", padding: "8px 16px", borderRadius: 8, textAlign: "center" }}>
                <span style={{ color: "#94a3b8", fontSize: "0.75rem", display: "block" }}>CREDITS</span>
                <span style={{ color: "#00FF88", fontSize: "1.4rem", fontWeight: 800 }}>{classInfo.credits}</span>
              </div>
            )}
          </div>
        </div>
      )}

      {/* GPS Session Control Panel */}
      <SessionPanel
        session={activeSession}
        busy={busy}
        onStart={handleStartSession}
        onStop={handleStopSession}
        onFinished={handleStopSession}
      />

      {/* Class History Sessions Table */}
      <div className="panel glass-panel" style={{ marginTop: 24, border: "1px solid #213042" }}>
        <h2>
          <Calendar size={20} color="#00E6FF" /> Class Session History
        </h2>
        <p style={{ color: "#94a3b8", fontSize: "0.85rem", marginBottom: 16 }}>
          Past attendance sessions taken for this class. Click any date to view individual student logs.
        </p>

        {historySessions.length === 0 ? (
          <div style={{ textAlign: "center", padding: "24px", color: "#94a3b8" }}>No attendance sessions conducted yet.</div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table className="table" style={{ width: "100%", textAlign: "left" }}>
              <thead>
                <tr>
                  <th>Session Date & Time</th>
                  <th>Verified Students</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {historySessions.map((s) => (
                  <tr key={s.sessionId} style={{ borderBottom: "1px solid #213042" }}>
                    <td style={{ color: "#ffffff", fontWeight: 600 }}>
                      <Clock size={14} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 6 }} />
                      {new Date(s.scannedAt).toLocaleString()}
                    </td>
                    <td style={{ color: "#00FF88", fontWeight: 700 }}>{s.count} Student(s)</td>
                    <td>
                      <button
                        type="button"
                        className="btn btn-secondary"
                        style={{ padding: "4px 12px", fontSize: "0.8rem" }}
                        onClick={() => navigate(`/teacher/class/${classId}/session/${s.sessionId}`)}
                      >
                        View Logs <ChevronRight size={14} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Active Students Section */}
      <div className="panel glass-panel" style={{ marginTop: 24, border: "1px solid #213042" }}>
        <h2>
          <Users size={20} color="#00E6FF" /> Active Students ({enrolledStudents.length})
        </h2>

        {enrolledStudents.length === 0 ? (
          <div style={{ textAlign: "center", padding: "24px", color: "#94a3b8" }}>
            <Users size={32} style={{ opacity: 0.3, marginBottom: 8 }} />
            <p style={{ margin: 0 }}>No students have joined yet.</p>
            <p style={{ margin: "4px 0 0", fontSize: "0.8rem" }}>Share the class code with students so they can join.</p>
          </div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table className="table" style={{ width: "100%", textAlign: "left" }}>
              <thead>
                <tr>
                  <th>#</th>
                  <th>Registration No</th>
                  <th>Name</th>
                  <th>Status</th>
                  <th>Joined At</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {enrolledStudents.map((s, idx) => (
                  <tr key={s.registrationNo} style={{ borderBottom: "1px solid #213042" }}>
                    <td style={{ color: "#94a3b8", fontSize: "0.85rem" }}>{idx + 1}</td>
                    <td style={{ color: "#ffffff", fontWeight: 700, fontFamily: "monospace" }}>{s.registrationNo}</td>
                    <td style={{ color: "#cbd5e1" }}>{s.name || "—"}</td>
                    <td>
                      <span className="badge badge-success" style={{ fontSize: "0.75rem" }}>Active</span>
                    </td>
                    <td style={{ color: "#94a3b8", fontSize: "0.8rem" }}>
                      {s.joinedAt ? new Date(s.joinedAt).toLocaleDateString() : "—"}
                    </td>
                    <td>
                      <button
                        type="button"
                        className="btn btn-secondary"
                        style={{ padding: "4px 12px", fontSize: "0.8rem", color: "#00E6FF" }}
                        onClick={() => openStudentModal(s)}
                      >
                        Manage
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Student Control Modal */}
      {selectedStudent && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.85)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
          <div className="panel glass-panel" style={{ width: "min(95vw, 680px)", maxHeight: "90vh", overflowY: "auto", border: "1px solid #00E6FF" }}>
            <div style={{ borderBottom: "1px solid #213042", paddingBottom: 12, marginBottom: 16 }}>
              {/* Registration Number (Large) */}
              <h2 style={{ fontSize: "2rem", fontWeight: 900, color: "#00E6FF", margin: 0, letterSpacing: "1px" }}>
                {selectedStudent.registrationNo}
              </h2>
              {/* Class ID (Small) */}
              <p style={{ color: "#94a3b8", fontSize: "0.8rem", margin: "4px 0 0" }}>CLASS ID: {classId}</p>
            </div>

            {/* Student Actions */}
            <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 20 }}>
              <button type="button" className="btn btn-secondary" style={{ color: "#00FF88", borderColor: "rgba(0, 255, 136, 0.4)" }} onClick={handleResetDevice} disabled={busy}>
                <Smartphone size={16} /> Reset Device ID
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                style={{ color: "#00E6FF", borderColor: "rgba(0, 230, 255, 0.4)" }}
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
                <KeyRound size={16} /> Reset Password
              </button>
              <button
                type="button"
                className={`btn ${showAdvance ? "btn-danger" : "btn-secondary"}`}
                style={{ marginLeft: "auto" }}
                onClick={() => setShowAdvance(!showAdvance)}
              >
                {showAdvance ? "Hide Advance Options" : "Advance Options"}
              </button>
            </div>

            {/* Advance Deletion Panel */}
            {showAdvance && (
              <div style={{ background: "rgba(239, 68, 68, 0.08)", border: "1px solid rgba(239, 68, 68, 0.3)", borderRadius: 12, padding: 16, marginBottom: 20 }}>
                <h4 style={{ color: "#ef4444", margin: "0 0 8px", display: "flex", alignItems: "center", gap: 6 }}>
                  <AlertTriangle size={18} /> Danger Zone Deletion Controls
                </h4>
                <p style={{ color: "#cbd5e1", fontSize: "0.85rem", marginBottom: 12 }}>
                  Deleting history will permanently remove attendance records for this student.
                </p>
                <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
                  <button
                    type="button"
                    className="btn"
                    style={{ background: "linear-gradient(135deg, #ef4444, #dc2626)", color: "#ffffff", fontWeight: 700 }}
                    onClick={confirmDeleteFullHistory}
                    disabled={busy}
                  >
                    <Trash2 size={16} /> Delete FULL Attendance History
                  </button>
                  {selectedRecordIds.length > 0 && (
                    <button
                      type="button"
                      className="btn"
                      style={{ background: "linear-gradient(135deg, #ef4444, #dc2626)", color: "#ffffff", fontWeight: 700 }}
                      onClick={confirmDeleteSelectedHistory}
                      disabled={busy}
                    >
                      <Trash2 size={16} /> Delete Selected ({selectedRecordIds.length}) Records
                    </button>
                  )}
                </div>
              </div>
            )}

            {/* History Table */}
            <h4 style={{ color: "#ffffff", marginBottom: 12 }}>Student Attendance History Records</h4>
            {studentHistory.length === 0 ? (
              <div style={{ textAlign: "center", padding: "20px", color: "#94a3b8" }}>No attendance recorded for this student in this class.</div>
            ) : (
              <div style={{ overflowX: "auto" }}>
                <table className="table" style={{ width: "100%", textAlign: "left" }}>
                  <thead>
                    <tr>
                      {showAdvance && <th>Select</th>}
                      <th>Date</th>
                      <th>Time</th>
                      <th>Device ID</th>
                    </tr>
                  </thead>
                  <tbody>
                    {studentHistory.map((h) => {
                      const d = new Date(h.scannedAt);
                      const isSelected = selectedRecordIds.includes(h.id);
                      return (
                        <tr key={h.id} style={{ borderBottom: "1px solid #213042", background: isSelected ? "rgba(239, 68, 68, 0.12)" : "transparent" }}>
                          {showAdvance && (
                            <td>
                              <input
                                type="checkbox"
                                checked={isSelected}
                                onChange={() => toggleRecordSelect(h.id)}
                                style={{ width: 18, height: 18, accentColor: "#ef4444" }}
                              />
                            </td>
                          )}
                          <td style={{ color: "#ffffff" }}>{d.toLocaleDateString()}</td>
                          <td style={{ color: "#00FF88", fontWeight: 600 }}>{d.toLocaleTimeString()}</td>
                          <td style={{ fontFamily: "monospace", fontSize: "0.8rem", color: "#94a3b8" }}>
                            {h.deviceInstallId ? h.deviceInstallId.slice(0, 16) + "..." : "Web/N/A"}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}

            <div style={{ textAlign: "right", marginTop: 20 }}>
              <button type="button" className="btn btn-secondary" onClick={() => setSelectedStudent(null)}>
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Confirmation Warning Modal */}
      {confirmModal.open && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.9)", zIndex: 10000, display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
          <div className="panel glass-panel" style={{ width: "min(90vw, 440px)", border: "2px solid #ef4444", textAlign: "center" }}>
            <AlertTriangle size={48} color="#ef4444" style={{ margin: "0 auto 12px" }} />
            <h3 style={{ color: "#ef4444", fontSize: "1.3rem", fontWeight: 800 }}>{confirmModal.title}</h3>
            <p style={{ color: "#e2e8f0", fontSize: "0.9rem", margin: "12px 0 24px" }}>{confirmModal.message}</p>
            <div style={{ display: "flex", gap: 12, justifyContent: "center" }}>
              <button type="button" className="btn btn-secondary" onClick={() => setConfirmModal({ open: false, type: null, data: null })}>
                Cancel
              </button>
              <button
                type="button"
                className="btn"
                style={{ background: "linear-gradient(135deg, #ef4444, #dc2626)", color: "#ffffff", fontWeight: 700 }}
                onClick={executeDeletion}
                disabled={busy}
              >
                Yes, Delete History
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
