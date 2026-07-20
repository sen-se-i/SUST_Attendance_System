import { useCallback, useEffect, useState } from "react";
import { Plus, Users } from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";
import { AttendanceTable } from "../components/AttendanceTable";
import { SessionPanel } from "../components/SessionPanel";

const initialClassForm = { department: "", academicSession: "", subjectCode: "" };

export default function TeacherDashboard() {
  const notify = useToast();
  const [classes, setClasses] = useState([]);
  const [selectedClass, setSelectedClass] = useState(null);
  const [attendance, setAttendance] = useState([]);
  const [session, setSession] = useState(null);
  const [classForm, setClassForm] = useState(initialClassForm);
  const [rosterText, setRosterText] = useState("");
  const [busy, setBusy] = useState(false);

  const loadClasses = useCallback(async () => {
    try {
      setClasses(await api("/api/classes"));
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to load classes", "danger");
    }
  }, [notify]);

  const loadAttendance = useCallback(
    async (classId) => {
      try {
        setAttendance(await api(`/api/attendance/classes/${classId}`));
      } catch (error) {
        notify(error instanceof ApiError ? error.message : "Failed to load attendance", "danger");
      }
    },
    [notify],
  );

  useEffect(() => {
    loadClasses();
  }, [loadClasses]);

  function selectClass(item) {
    setSelectedClass(item);
    setSession(null);
    setRosterText("");
    loadAttendance(item.id);
  }

  async function handleCreateClass(event) {
    event.preventDefault();
    setBusy(true);
    try {
      await api("/api/classes", { method: "POST", body: JSON.stringify(classForm) });
      setClassForm(initialClassForm);
      await loadClasses();
      notify("Class created.", "success");
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to create class", "danger");
    } finally {
      setBusy(false);
    }
  }

  async function handleSaveRoster(event) {
    event.preventDefault();
    if (!selectedClass) return;
    const registrationNos = rosterText
      .split(/\r?\n/)
      .map((s) => s.trim())
      .filter(Boolean);
    if (!registrationNos.length) return;
    setBusy(true);
    try {
      const result = await api(`/api/classes/${selectedClass.id}/roster`, {
        method: "POST",
        body: JSON.stringify({ registrationNos }),
      });
      notify(`Roster saved (${result.accepted} accepted).`, "success");
      setRosterText("");
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to save roster", "danger");
    } finally {
      setBusy(false);
    }
  }

  async function startSession() {
    if (!selectedClass) return;
    setBusy(true);
    try {
      const started = await api("/api/sessions/start", {
        method: "POST",
        body: JSON.stringify({ classId: selectedClass.id, totalTicks: 40, intervalSeconds: 3 }),
      });
      setSession(started);
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to start session", "danger");
    } finally {
      setBusy(false);
    }
  }

  async function stopSession() {
    if (!session) return;
    setBusy(true);
    try {
      await api(`/api/sessions/${session.sessionId}/stop`, { method: "POST" });
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to stop session", "danger");
    } finally {
      setSession(null);
      setBusy(false);
      if (selectedClass) await loadAttendance(selectedClass.id);
    }
  }

  return (
    <div className="workspace">
      <aside className="sidebar">
        <form className="panel glass-panel compact" onSubmit={handleCreateClass}>
          <h2>
            <Plus size={18} /> New Class
          </h2>
          <div className="form-group">
            <label className="form-label" htmlFor="department">
              Department
            </label>
            <input
              id="department"
              className="form-input"
              required
              placeholder="CSE"
              value={classForm.department}
              onChange={(e) => setClassForm((f) => ({ ...f, department: e.target.value }))}
            />
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="academicSession">
              Session
            </label>
            <input
              id="academicSession"
              className="form-input"
              required
              placeholder="2026"
              value={classForm.academicSession}
              onChange={(e) => setClassForm((f) => ({ ...f, academicSession: e.target.value }))}
            />
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="subjectCode">
              Subject
            </label>
            <input
              id="subjectCode"
              className="form-input"
              required
              placeholder="CSE101"
              value={classForm.subjectCode}
              onChange={(e) => setClassForm((f) => ({ ...f, subjectCode: e.target.value }))}
            />
          </div>
          <button type="submit" className="btn btn-primary" disabled={busy}>
            Create
          </button>
        </form>

        <div className="panel glass-panel compact">
          <h2>
            <Users size={18} /> Classes
          </h2>
          <div className="list">
            {classes.length === 0 && <p className="empty-state">No classes yet.</p>}
            {classes.map((item) => (
              <button
                key={item.id}
                type="button"
                className={`list-item${selectedClass?.id === item.id ? " active" : ""}`}
                onClick={() => selectClass(item)}
              >
                {item.subjectCode} · {item.code}
              </button>
            ))}
          </div>
        </div>
      </aside>

      <section className="main-panel">
        {!selectedClass ? (
          <div className="empty-state-block">Create or select a class.</div>
        ) : (
          <>
            <div className="toolbar class-header">
              <div>
                <h2>
                  {selectedClass.subjectCode} · {selectedClass.department}
                </h2>
                <p className="subtitle">Class code: {selectedClass.code}</p>
              </div>
            </div>

            <form className="panel glass-panel" onSubmit={handleSaveRoster}>
              <h3>Roster</h3>
              <textarea
                className="form-input"
                rows={6}
                placeholder="One registration number per line"
                value={rosterText}
                onChange={(e) => setRosterText(e.target.value)}
              />
              <button type="submit" className="btn btn-secondary" disabled={busy}>
                Save Roster
              </button>
            </form>

            <SessionPanel session={session} onStart={startSession} onStop={stopSession} busy={busy} />

            <div className="panel glass-panel">
              <h3>Attendance</h3>
              <AttendanceTable rows={attendance} emptyLabel="No scans yet." showRegistration />
            </div>
          </>
        )}
      </section>
    </div>
  );
}
