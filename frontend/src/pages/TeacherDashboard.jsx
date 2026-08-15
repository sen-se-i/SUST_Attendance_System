import { useCallback, useEffect, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { Plus, RefreshCw, Users, BookOpen, AlertCircle, ChevronRight, ChevronDown } from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";
import { DEPARTMENTS, SEMESTERS, SUBJECT_CATALOG } from "../data/subjectCatalog";

function CustomSelect({ options, value, onChange, placeholder = "Select option", isError }) {
  const [open, setOpen] = useState(false);
  const containerRef = useRef(null);

  useEffect(() => {
    function handleClickOutside(e) {
      if (containerRef.current && !containerRef.current.contains(e.target)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const selectedOption = options.find((o) => o.value === value);

  return (
    <div ref={containerRef} style={{ position: "relative", width: "100%" }}>
      <button
        type="button"
        onClick={() => setOpen(!open)}
        style={{
          width: "100%",
          padding: "12px 16px",
          background: "#0D1520",
          border: isError ? "1px solid #ef4444" : open ? "1px solid #00E6FF" : "1px solid #213042",
          borderRadius: 10,
          color: "#ffffff",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          cursor: "pointer",
          textAlign: "left",
          fontSize: "0.92rem",
          boxShadow: open ? "0 0 14px rgba(0, 230, 255, 0.3)" : "none",
          transition: "all 0.2s ease",
        }}
      >
        <span style={{ color: selectedOption ? "#ffffff" : "#94a3b8", fontWeight: 600 }}>
          {selectedOption ? selectedOption.label : placeholder}
        </span>
        <ChevronDown size={18} color="#00E6FF" style={{ transform: open ? "rotate(180deg)" : "none", transition: "transform 0.2s ease" }} />
      </button>

      {open && (
        <div
          style={{
            position: "absolute",
            top: "calc(100% + 6px)",
            left: 0,
            right: 0,
            zIndex: 99999,
            background: "#090F17",
            border: "1px solid #00E6FF",
            borderRadius: 12,
            maxHeight: 240,
            overflowY: "auto",
            boxShadow: "0 12px 36px rgba(0,0,0,0.95), 0 0 16px rgba(0, 230, 255, 0.25)",
            padding: 6,
          }}
        >
          {options.map((opt) => {
            const isSelected = opt.value === value;
            return (
              <div
                key={opt.value}
                onClick={() => {
                  onChange(opt.value);
                  setOpen(false);
                }}
                style={{
                  padding: "11px 14px",
                  borderRadius: 8,
                  color: isSelected ? "#00E6FF" : "#e2e8f0",
                  background: isSelected ? "rgba(0, 230, 255, 0.15)" : "transparent",
                  fontWeight: isSelected ? 700 : 500,
                  fontSize: "0.9rem",
                  cursor: "pointer",
                  transition: "all 0.15s ease",
                  marginBottom: 2,
                }}
                onMouseEnter={(e) => {
                  if (!isSelected) e.currentTarget.style.background = "rgba(255, 255, 255, 0.08)";
                }}
                onMouseLeave={(e) => {
                  if (!isSelected) e.currentTarget.style.background = "transparent";
                }}
              >
                {opt.label}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

const initialForm = {
  department: DEPARTMENTS[0],
  academicSession: "2023-24",
  semester: SEMESTERS[0],
  subjectCode: "",
  subjectName: "",
  credits: 3.0,
};

export default function TeacherDashboard() {
  const navigate = useNavigate();
  const notify = useToast();

  const [classes, setClasses] = useState([]);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [form, setForm] = useState(initialForm);
  const [availableSubjects, setAvailableSubjects] = useState([]);
  const [busy, setBusy] = useState(false);

  // Validation States
  const [sessionError, setSessionError] = useState("");
  const [duplicateError, setDuplicateError] = useState("");

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

  // Update subject dropdown when Department or Semester changes
  useEffect(() => {
    const deptSubjects = SUBJECT_CATALOG[form.department] || {};
    const semSubjects = deptSubjects[form.semester] || [];
    setAvailableSubjects(semSubjects);
    if (semSubjects.length > 0) {
      setForm((prev) => ({
        ...prev,
        subjectCode: semSubjects[0].code,
        subjectName: semSubjects[0].name,
        credits: semSubjects[0].credits,
      }));
    } else {
      setForm((prev) => ({ ...prev, subjectCode: "", subjectName: "", credits: 3.0 }));
    }
  }, [form.department, form.semester]);

  // Instant Session Format Check
  function handleSessionChange(value) {
    setForm((prev) => ({ ...prev, academicSession: value }));
    const sessionRegex = /^\d{4}-\d{2}$/;
    if (value && !sessionRegex.test(value)) {
      setSessionError("Format must be YYYY-YY (e.g. 2023-24)");
    } else {
      setSessionError("");
    }
    checkDuplicate(value, form.semester, form.subjectCode);
  }

  // Instant Duplicate Check
  function checkDuplicate(sessionVal, semVal, codeVal) {
    if (!sessionVal || !semVal || !codeVal) {
      setDuplicateError("");
      return;
    }
    const isDup = classes.some(
      (c) => c.academicSession === sessionVal && c.semester === semVal && c.subjectCode === codeVal
    );
    if (isDup) {
      setDuplicateError(`A class for subject ${codeVal} already exists in session ${sessionVal} (${semVal}).`);
    } else {
      setDuplicateError("");
    }
  }

  function handleSubjectSelect(code) {
    const found = availableSubjects.find((s) => s.code === code);
    if (found) {
      setForm((prev) => ({
        ...prev,
        subjectCode: found.code,
        subjectName: found.name,
        credits: found.credits,
      }));
      checkDuplicate(form.academicSession, form.semester, found.code);
    }
  }

  async function handleCreateClass(e) {
    e.preventDefault();
    if (sessionError || duplicateError) return;

    setBusy(true);
    try {
      const created = await api("/api/classes", {
        method: "POST",
        body: JSON.stringify(form),
      });
      notify(`Class created successfully! Join Code: ${created.code}`, "success");
      setShowCreateModal(false);
      setForm(initialForm);
      await loadClasses();
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to create class", "danger");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ paddingBottom: 100 }}>
      {/* Top Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
        <div>
          <h1 style={{ fontSize: "1.8rem", fontWeight: 800, color: "#ffffff", margin: 0 }}>Active Teacher Classes</h1>
          <p style={{ color: "#94a3b8", fontSize: "0.9rem", margin: "4px 0 0" }}>Select any class to manage sessions and attendance.</p>
        </div>
        <button type="button" className="btn btn-secondary" onClick={loadClasses}>
          <RefreshCw size={16} /> Refresh
        </button>
      </div>

      {/* Active Classes Grid */}
      {classes.length === 0 ? (
        <div className="panel glass-panel" style={{ textAlign: "center", padding: "48px 24px", border: "1px dashed #213042" }}>
          <BookOpen size={48} color="#3B4D61" style={{ marginBottom: 12 }} />
          <h3 style={{ color: "#ffffff" }}>No Active Classes Created</h3>
          <p style={{ color: "#94a3b8", fontSize: "0.9rem", marginBottom: 20 }}>
            Click the "+ CREATE" button at the bottom of the screen to add your first course.
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
              onClick={() => navigate(`/teacher/class/${item.id}`)}
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
              <p style={{ color: "#00E6FF", fontSize: "0.85rem", fontWeight: 600, margin: "0 0 12px" }}>
                {item.subjectCode} &nbsp;•&nbsp; {item.academicSession} &nbsp;•&nbsp; {item.semester || ""}
              </p>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid #213042", paddingTop: 12, marginTop: 12, fontSize: "0.8rem", color: "#94a3b8" }}>
                <span>{item.department}</span>
                <span style={{ color: "#00E6FF", fontWeight: 700, display: "inline-flex", alignItems: "center", gap: 4 }}>
                  Open Details <ChevronRight size={14} />
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Floating Bottom "+ CREATE" Button */}
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
          }}
          onClick={() => setShowCreateModal(true)}
        >
          <Plus size={20} /> + CREATE CLASS
        </button>
      </div>

      {/* Create Class Modal */}
      {showCreateModal && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.85)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
          <div className="panel glass-panel" style={{ width: "min(95vw, 560px)", border: "1px solid #00E6FF", maxHeight: "90vh", overflowY: "auto" }}>
            <h2 style={{ fontSize: "1.4rem", fontWeight: 800, color: "#ffffff", marginBottom: 16 }}>Create New Class</h2>

            <form onSubmit={handleCreateClass}>
              {/* Department Dropdown */}
              <div className="form-group" style={{ marginBottom: 14 }}>
                <label className="form-label">Department</label>
                <CustomSelect
                  options={DEPARTMENTS.map((d) => ({ value: d, label: d }))}
                  value={form.department}
                  onChange={(val) => setForm((prev) => ({ ...prev, department: val }))}
                />
              </div>

              {/* Session Input (with YYYY-YY regex validation) */}
              <div className="form-group" style={{ marginBottom: 14 }}>
                <label className="form-label">Academic Session (Format: YYYY-YY)</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="2023-24"
                  value={form.academicSession}
                  onChange={(e) => handleSessionChange(e.target.value)}
                  style={{
                    borderColor: sessionError || (duplicateError && form.academicSession) ? "#ef4444" : "#213042",
                    background: duplicateError ? "rgba(239, 68, 68, 0.1)" : undefined,
                  }}
                  required
                />
                {sessionError && (
                  <p style={{ color: "#ef4444", fontSize: "0.8rem", marginTop: 4, display: "flex", alignItems: "center", gap: 4 }}>
                    <AlertCircle size={14} /> {sessionError}
                  </p>
                )}
              </div>

              {/* Semester Dropdown */}
              <div className="form-group" style={{ marginBottom: 14 }}>
                <label className="form-label">Semester</label>
                <CustomSelect
                  options={SEMESTERS.map((s) => ({ value: s, label: s }))}
                  value={form.semester}
                  onChange={(val) => {
                    setForm((prev) => ({ ...prev, semester: val }));
                    checkDuplicate(form.academicSession, val, form.subjectCode);
                  }}
                  isError={!!duplicateError}
                />
              </div>

              {/* Subject Dropdown */}
              <div className="form-group" style={{ marginBottom: 14 }}>
                <label className="form-label">Subject</label>
                {form.department !== "Software Engineering" ? (
                  <div style={{ background: "rgba(245, 158, 11, 0.12)", border: "1px solid rgba(245, 158, 11, 0.4)", padding: 12, borderRadius: 8, color: "#fbbf24", fontSize: "0.85rem", display: "flex", alignItems: "center", gap: 6 }}>
                    <AlertCircle size={16} /> subjects for this department hasn't been updated
                  </div>
                ) : availableSubjects.length === 0 ? (
                  <p style={{ color: "#94a3b8", fontSize: "0.85rem" }}>No pre-configured subjects for this semester.</p>
                ) : (
                  <CustomSelect
                    options={availableSubjects.map((sub) => ({ value: sub.code, label: sub.name }))}
                    value={form.subjectCode}
                    onChange={(val) => handleSubjectSelect(val)}
                    isError={!!duplicateError}
                  />
                )}
              </div>

              {/* Pre-populated Details Preview */}
              {form.subjectCode && (
                <div style={{ background: "rgba(0, 230, 255, 0.08)", border: "1px solid #213042", padding: 12, borderRadius: 8, marginBottom: 16 }}>
                  <span style={{ color: "#00E6FF", fontWeight: 700, fontSize: "0.85rem" }}>
                    Selected: {form.subjectName} ({form.subjectCode})
                  </span>
                  <span style={{ color: "#00FF88", fontWeight: 700, fontSize: "0.85rem", marginLeft: 12 }}>
                    Credits: {form.credits}
                  </span>
                </div>
              )}

              {/* Duplicate Error Banner */}
              {duplicateError && (
                <div style={{ background: "rgba(239, 68, 68, 0.15)", border: "1px solid #ef4444", padding: 12, borderRadius: 8, marginBottom: 16, color: "#ef4444", fontSize: "0.85rem" }}>
                  <AlertCircle size={16} style={{ verticalAlign: "middle", marginRight: 6 }} />
                  {duplicateError}
                </div>
              )}

              <div style={{ display: "flex", gap: 12, justifyContent: "flex-end", marginTop: 20 }}>
                <button type="button" className="btn btn-secondary" onClick={() => setShowCreateModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={busy || !!sessionError || !!duplicateError}>
                  Create Class
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
