import { useCallback, useEffect, useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import {
  BookOpen,
  Users,
  GraduationCap,
  Plus,
  RefreshCw,
  AlertCircle,
  CheckCircle2,
  Lock,
  ChevronDown,
  Clock,
  UserCheck,
  Search,
  FileSpreadsheet,
  Printer,
  X,
  PowerOff,
  User,
  Shield,
} from "lucide-react";
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

function deriveDepartmentFromReg(regNo) {
  if (!regNo || regNo.length < 7) return "Software Engineering";
  const code = regNo.substring(4, 7);
  switch (code) {
    case "831":
      return "Software Engineering";
    case "331":
      return "Computer Science and Engineering";
    case "332":
      return "Electrical and Electronic Engineering";
    case "134":
      return "Civil and Environmental Engineering";
    case "334":
      return "Chemical Engineering and Polymer Science";
    case "333":
      return "Industrial and Production Engineering";
    default:
      return "Software Engineering";
  }
}

function deriveSessionFromReg(regNo) {
  if (!regNo || regNo.length < 4) return "2023-24";
  const yearStr = regNo.substring(0, 4);
  const year = parseInt(yearStr, 10);
  if (isNaN(year)) return "2023-24";
  const nextYearShort = (year + 1) % 100;
  return `${year}-${String(nextYearShort).padStart(2, "0")}`;
}

export default function AdminDashboard() {
  const navigate = useNavigate();
  const notify = useToast();

  const [activeTab, setActiveTab] = useState("classes"); // 'classes', 'create_student', 'create_teacher', 'create_class', 'passwords'
  const [classes, setClasses] = useState([]);
  const [teachers, setTeachers] = useState([]);
  const [busy, setBusy] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("ALL");

  // Create Student Form
  const [studentRegNo, setStudentRegNo] = useState("");
  const [studentPassword, setStudentPassword] = useState("");
  const [createdStudentResult, setCreatedStudentResult] = useState(null);

  // Create Teacher Form
  const [teacherEmail, setTeacherEmail] = useState("");
  const [teacherPassword, setTeacherPassword] = useState("");
  const [teacherDept, setTeacherDept] = useState(DEPARTMENTS[0]);
  const [createdTeacherResult, setCreatedTeacherResult] = useState(null);

  // Create Class Form
  const [classForm, setClassForm] = useState({
    department: DEPARTMENTS[0],
    academicSession: "2023-24",
    semester: SEMESTERS[0],
    subjectCode: "",
    subjectName: "",
    credits: 3.0,
    teacherId: "",
  });
  const [availableSubjects, setAvailableSubjects] = useState([]);
  const [deptTeachers, setDeptTeachers] = useState([]);

  // Password Reset Form
  const [resetIdentifier, setResetIdentifier] = useState("");
  const [resetNewPassword, setResetNewPassword] = useState("");

  // End Class Confirmation Modal
  const [endClassModal, setEndClassModal] = useState({ open: false, cls: null });

  // Matrix Report Modal
  const [matrixModal, setMatrixModal] = useState({ open: false, data: null, loading: false });

  const loadClasses = useCallback(async () => {
    try {
      const data = await api("/api/admin/classes");
      setClasses(data);
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to load classes", "danger");
    }
  }, [notify]);

  const loadTeachers = useCallback(async () => {
    try {
      const data = await api("/api/admin/teachers");
      setTeachers(data);
    } catch (error) {
      console.error(error);
    }
  }, []);

  useEffect(() => {
    loadClasses();
    loadTeachers();
  }, [loadClasses, loadTeachers]);

  // Subject Catalog Auto-update
  useEffect(() => {
    const deptSubjects = SUBJECT_CATALOG[classForm.department] || {};
    const semSubjects = deptSubjects[classForm.semester] || [];
    setAvailableSubjects(semSubjects);
    if (semSubjects.length > 0) {
      setClassForm((prev) => ({
        ...prev,
        subjectCode: semSubjects[0].code,
        subjectName: semSubjects[0].name,
        credits: semSubjects[0].credits,
      }));
    } else {
      setClassForm((prev) => ({ ...prev, subjectCode: "", subjectName: "", credits: 3.0 }));
    }
  }, [classForm.department, classForm.semester]);

  // Load teachers for the selected department
  useEffect(() => {
    if (classForm.department) {
      api(`/api/admin/teachers?department=${encodeURIComponent(classForm.department)}`)
        .then((data) => {
          setDeptTeachers(data);
          if (data.length > 0) {
            setClassForm((prev) => ({ ...prev, teacherId: data[0].id }));
          } else {
            setClassForm((prev) => ({ ...prev, teacherId: "" }));
          }
        })
        .catch(() => setDeptTeachers([]));
    }
  }, [classForm.department]);

  // Handle Student Creation
  async function handleCreateStudent(e) {
    e.preventDefault();
    if (!studentRegNo.trim() || !studentPassword.trim()) return;

    setBusy(true);
    setCreatedStudentResult(null);
    try {
      const result = await api("/api/admin/students", {
        method: "POST",
        body: JSON.stringify({
          registrationNo: studentRegNo.trim(),
          password: studentPassword.trim(),
        }),
      });
      setCreatedStudentResult(result);
      notify(`Student ${result.registrationNo} created successfully!`, "success");
      setStudentRegNo("");
      setStudentPassword("");
      await loadClasses();
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to create student", "danger");
    } finally {
      setBusy(false);
    }
  }

  // Handle Teacher Creation
  async function handleCreateTeacher(e) {
    e.preventDefault();
    if (!teacherEmail.trim() || !teacherPassword.trim()) return;

    setBusy(true);
    setCreatedTeacherResult(null);
    try {
      const result = await api("/api/admin/teachers", {
        method: "POST",
        body: JSON.stringify({
          email: teacherEmail.trim().toLowerCase(),
          password: teacherPassword.trim(),
          department: teacherDept,
        }),
      });
      setCreatedTeacherResult(result);
      notify(`Teacher ${result.email} created successfully!`, "success");
      setTeacherEmail("");
      setTeacherPassword("");
      await loadTeachers();
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to create teacher", "danger");
    } finally {
      setBusy(false);
    }
  }

  // Handle Class Creation
  async function handleCreateClass(e) {
    e.preventDefault();
    setBusy(true);
    try {
      const created = await api("/api/admin/classes", {
        method: "POST",
        body: JSON.stringify(classForm),
      });
      notify(`Class ${created.code} created! Auto-enrolled ${created.enrolledCount} students.`, "success");
      setActiveTab("classes");
      await loadClasses();
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to create class", "danger");
    } finally {
      setBusy(false);
    }
  }

  // Handle End Class
  async function handleEndClass() {
    if (!endClassModal.cls) return;
    setBusy(true);
    try {
      await api(`/api/admin/classes/${endClassModal.cls.id}/end`, { method: "POST" });
      notify(`Class ${endClassModal.cls.code} ended and archived`, "success");
      setEndClassModal({ open: false, cls: null });
      await loadClasses();
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to end class", "danger");
    } finally {
      setBusy(false);
    }
  }

  // Handle Admin Password Reset
  async function handleResetPassword(e) {
    e.preventDefault();
    if (!resetIdentifier.trim() || !resetNewPassword.trim()) return;

    setBusy(true);
    try {
      const res = await api("/api/admin/users/reset-password", {
        method: "POST",
        body: JSON.stringify({
          identifier: resetIdentifier.trim(),
          newPassword: resetNewPassword.trim(),
        }),
      });
      notify(res.message || "Password changed successfully!", "success");
      setResetIdentifier("");
      setResetNewPassword("");
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to reset password", "danger");
    } finally {
      setBusy(false);
    }
  }

  // Open Matrix Report Modal
  async function openMatrixReport(classId) {
    setMatrixModal({ open: true, data: null, loading: true });
    try {
      const report = await api(`/api/classes/${classId}/report/matrix`);
      setMatrixModal({ open: true, data: report, loading: false });
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to generate report", "danger");
      setMatrixModal({ open: false, data: null, loading: false });
    }
  }

  const filteredClasses = classes.filter((c) => {
    const matchesSearch =
      (c.subjectName && c.subjectName.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (c.subjectCode && c.subjectCode.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (c.code && c.code.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (c.department && c.department.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (c.teacherName && c.teacherName.toLowerCase().includes(searchQuery.toLowerCase()));

    const matchesStatus =
      statusFilter === "ALL" ||
      (statusFilter === "ACTIVE" && (c.status === "ACTIVE" || !c.status)) ||
      (statusFilter === "ENDED" && c.status === "ENDED");

    return matchesSearch && matchesStatus;
  });

  return (
    <div style={{ paddingBottom: 80 }}>
      {/* Top Header & Metrics */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20, flexWrap: "wrap", gap: 12 }}>
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <h1 style={{ fontSize: "1.6rem", fontWeight: 900, color: "#ffffff", margin: 0 }}>Administrator Console</h1>
            <span className="badge badge-success" style={{ background: "rgba(0, 230, 255, 0.15)", color: "#00E6FF", border: "1px solid #00E6FF" }}>
              <Shield size={12} style={{ marginRight: 4, verticalAlign: "middle" }} /> System Admin
            </span>
          </div>
          <p style={{ color: "#94a3b8", fontSize: "0.85rem", margin: "4px 0 0" }}>
            Central administration for course creation, automatic student enrollment, and attendance records.
          </p>
        </div>
        <button type="button" className="btn btn-secondary" style={{ padding: "8px 16px", fontSize: "0.85rem" }} onClick={loadClasses}>
          <RefreshCw size={14} /> Refresh Data
        </button>
      </div>

      {/* Navigation Tabs */}
      <div style={{ display: "flex", gap: 8, overflowX: "auto", borderBottom: "1px solid #213042", paddingBottom: 12, marginBottom: 24 }}>
        <button
          type="button"
          className={`btn ${activeTab === "classes" ? "btn-primary" : "btn-secondary"}`}
          style={{ fontSize: "0.88rem", padding: "8px 16px", display: "flex", alignItems: "center", gap: 6 }}
          onClick={() => setActiveTab("classes")}
        >
          <BookOpen size={16} /> All Classes ({classes.length})
        </button>
        <button
          type="button"
          className={`btn ${activeTab === "create_class" ? "btn-primary" : "btn-secondary"}`}
          style={{ fontSize: "0.88rem", padding: "8px 16px", display: "flex", alignItems: "center", gap: 6 }}
          onClick={() => setActiveTab("create_class")}
        >
          <Plus size={16} /> + Create Class
        </button>
        <button
          type="button"
          className={`btn ${activeTab === "create_student" ? "btn-primary" : "btn-secondary"}`}
          style={{ fontSize: "0.88rem", padding: "8px 16px", display: "flex", alignItems: "center", gap: 6 }}
          onClick={() => setActiveTab("create_student")}
        >
          <GraduationCap size={16} /> Create Student
        </button>
        <button
          type="button"
          className={`btn ${activeTab === "create_teacher" ? "btn-primary" : "btn-secondary"}`}
          style={{ fontSize: "0.88rem", padding: "8px 16px", display: "flex", alignItems: "center", gap: 6 }}
          onClick={() => setActiveTab("create_teacher")}
        >
          <Users size={16} /> Create Teacher
        </button>
        <button
          type="button"
          className={`btn ${activeTab === "passwords" ? "btn-primary" : "btn-secondary"}`}
          style={{ fontSize: "0.88rem", padding: "8px 16px", display: "flex", alignItems: "center", gap: 6 }}
          onClick={() => setActiveTab("passwords")}
        >
          <Lock size={16} /> Password Management
        </button>
      </div>

      {/* TAB 1: ALL CLASSES VIEW */}
      {activeTab === "classes" && (
        <div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 12, marginBottom: 18, flexWrap: "wrap" }}>
            <div style={{ position: "relative", minWidth: 260, flex: 1 }}>
              <Search size={16} color="#94a3b8" style={{ position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)" }} />
              <input
                type="text"
                className="form-input"
                placeholder="Search classes by subject, code, teacher, dept..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{ paddingLeft: 36 }}
              />
            </div>
            <div style={{ display: "flex", gap: 6 }}>
              {["ALL", "ACTIVE", "ENDED"].map((st) => (
                <button
                  key={st}
                  type="button"
                  className={`btn ${statusFilter === st ? "btn-primary" : "btn-secondary"}`}
                  style={{ fontSize: "0.8rem", padding: "6px 12px" }}
                  onClick={() => setStatusFilter(st)}
                >
                  {st}
                </button>
              ))}
            </div>
          </div>

          {filteredClasses.length === 0 ? (
            <div className="panel glass-panel" style={{ textAlign: "center", padding: "40px 20px" }}>
              <BookOpen size={40} color="#3B4D61" style={{ marginBottom: 12 }} />
              <h3 style={{ fontSize: "1.1rem" }}>No Classes Found</h3>
              <p style={{ color: "#94a3b8", fontSize: "0.88rem" }}>
                Click "+ Create Class" to set up a new course and auto-enroll students.
              </p>
            </div>
          ) : (
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: 18 }}>
              {filteredClasses.map((item) => {
                const isEnded = item.status === "ENDED";
                return (
                  <div
                    key={item.id}
                    className="panel glass-panel"
                    style={{
                      border: isEnded ? "1px solid #334155" : "1px solid #213042",
                      opacity: isEnded ? 0.75 : 1,
                      padding: "18px",
                      transition: "all 0.2s ease",
                    }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 }}>
                      <span className={`badge ${isEnded ? "badge-secondary" : "badge-success"}`} style={{ fontSize: "0.75rem", fontFamily: "monospace" }}>
                        {item.code} {isEnded ? "• ENDED" : ""}
                      </span>
                      {item.credits && (
                        <span style={{ fontWeight: 700, fontSize: "0.8rem", color: "#00FF88" }}>{item.credits} Credits</span>
                      )}
                    </div>

                    <h3 style={{ fontSize: "1.2rem", fontWeight: 800, color: "#ffffff", margin: "0 0 4px" }}>
                      {item.subjectName || item.subjectCode}
                    </h3>
                    <p style={{ color: "#00E6FF", fontSize: "0.82rem", fontWeight: 600, margin: "0 0 8px" }}>
                      {item.subjectCode} • {item.academicSession} {item.semester ? `• ${item.semester}` : ""}
                    </p>

                    <div style={{ background: "#090F17", border: "1px solid #213042", padding: "8px 12px", borderRadius: 8, fontSize: "0.8rem", marginBottom: 12, color: "#94a3b8" }}>
                      <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 4 }}>
                        <User size={14} color="#00E6FF" /> Teacher: <strong style={{ color: "#ffffff" }}>{item.teacherName || "Assigned Faculty"}</strong>
                      </div>
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                        <span>
                          <UserCheck size={14} color="#00FF88" style={{ verticalAlign: "middle", marginRight: 4 }} />
                          {item.enrolledCount} Enrolled
                        </span>
                        <span>
                          <Clock size={14} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 4 }} />
                          {item.totalSessions} Sessions
                        </span>
                      </div>
                    </div>

                    <div style={{ display: "flex", gap: 8, marginTop: 12 }}>
                      <button
                        type="button"
                        className="btn btn-secondary"
                        style={{ flex: 1, padding: "8px", fontSize: "0.8rem", display: "flex", alignItems: "center", justifyContent: "center", gap: 6 }}
                        onClick={() => openMatrixReport(item.id)}
                      >
                        <FileSpreadsheet size={14} color="#00E6FF" /> Matrix Report
                      </button>
                      <button
                        type="button"
                        className="btn btn-secondary"
                        style={{ padding: "8px 12px", fontSize: "0.8rem" }}
                        onClick={() => navigate(`/admin/class/${item.id}`)}
                      >
                        Details
                      </button>
                      {!isEnded && (
                        <button
                          type="button"
                          className="btn btn-danger"
                          style={{ padding: "8px 10px", fontSize: "0.8rem" }}
                          title="End Class (Archive from active views)"
                          onClick={() => setEndClassModal({ open: true, cls: item })}
                        >
                          <PowerOff size={14} />
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* TAB 2: CREATE STUDENT */}
      {activeTab === "create_student" && (
        <div style={{ maxWidth: 540, margin: "0 auto" }}>
          <div className="panel glass-panel" style={{ border: "1px solid #00E6FF", padding: 24 }}>
            <h2 style={{ fontSize: "1.3rem", fontWeight: 800, color: "#ffffff", marginBottom: 6 }}>
              <GraduationCap size={22} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 8 }} />
              Create Student Account
            </h2>
            <p style={{ color: "#94a3b8", fontSize: "0.85rem", marginBottom: 20 }}>
              Enter the student's registration number and password. Department and session are calculated automatically from the registration number.
            </p>

            <form onSubmit={handleCreateStudent}>
              <div className="form-group" style={{ marginBottom: 16 }}>
                <label className="form-label">Registration Number</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="e.g. 2023831018"
                  value={studentRegNo}
                  onChange={(e) => {
                    const val = e.target.value.trim();
                    setStudentRegNo(val);
                    if (!studentPassword) setStudentPassword(val);
                  }}
                  maxLength={15}
                  required
                />
              </div>

              {/* Live Detection Preview */}
              {studentRegNo.length >= 4 && (
                <div style={{ background: "rgba(0, 230, 255, 0.08)", border: "1px solid #213042", borderRadius: 10, padding: 14, marginBottom: 16 }}>
                  <span style={{ color: "#94a3b8", fontSize: "0.75rem", display: "block", fontWeight: 700, marginBottom: 6 }}>
                    AUTO-DETECTED STUDENT PROFILE:
                  </span>
                  <div style={{ display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 8 }}>
                    <span style={{ color: "#00E6FF", fontWeight: 700, fontSize: "0.9rem" }}>
                      Dept: {deriveDepartmentFromReg(studentRegNo)}
                    </span>
                    <span style={{ color: "#00FF88", fontWeight: 700, fontSize: "0.9rem" }}>
                      Session: {deriveSessionFromReg(studentRegNo)}
                    </span>
                  </div>
                </div>
              )}

              <div className="form-group" style={{ marginBottom: 20 }}>
                <label className="form-label">Password</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="Password (defaults to registration number)"
                  value={studentPassword}
                  onChange={(e) => setStudentPassword(e.target.value)}
                  required
                />
              </div>

              <button type="submit" className="btn btn-primary" style={{ width: "100%", padding: "12px", fontWeight: 800 }} disabled={busy}>
                {busy ? "Creating Student..." : "Create Student Account"}
              </button>
            </form>

            {createdStudentResult && (
              <div style={{ marginTop: 20, background: "rgba(0, 255, 136, 0.1)", border: "1px solid #00FF88", borderRadius: 10, padding: 14, color: "#00FF88" }}>
                <CheckCircle2 size={18} style={{ verticalAlign: "middle", marginRight: 6 }} />
                <strong>Student Created Successfully!</strong>
                <div style={{ fontSize: "0.85rem", color: "#ffffff", marginTop: 6 }}>
                  Reg: <strong>{createdStudentResult.registrationNo}</strong> • Dept: <strong>{createdStudentResult.department}</strong> • Session: <strong>{createdStudentResult.academicSession}</strong>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* TAB 3: CREATE TEACHER */}
      {activeTab === "create_teacher" && (
        <div style={{ maxWidth: 540, margin: "0 auto" }}>
          <div className="panel glass-panel" style={{ border: "1px solid #00E6FF", padding: 24 }}>
            <h2 style={{ fontSize: "1.3rem", fontWeight: 800, color: "#ffffff", marginBottom: 6 }}>
              <Users size={22} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 8 }} />
              Create Teacher Account
            </h2>
            <p style={{ color: "#94a3b8", fontSize: "0.85rem", marginBottom: 20 }}>
              Add a new faculty member with their institutional email, department, and initial password.
            </p>

            <form onSubmit={handleCreateTeacher}>
              <div className="form-group" style={{ marginBottom: 16 }}>
                <label className="form-label">Teacher Email</label>
                <input
                  type="email"
                  className="form-input"
                  placeholder="teacher@sust.edu"
                  value={teacherEmail}
                  onChange={(e) => setTeacherEmail(e.target.value)}
                  required
                />
              </div>

              <div className="form-group" style={{ marginBottom: 16 }}>
                <label className="form-label">Department</label>
                <CustomSelect
                  options={DEPARTMENTS.map((d) => ({ value: d, label: d }))}
                  value={teacherDept}
                  onChange={(val) => setTeacherDept(val)}
                />
              </div>

              <div className="form-group" style={{ marginBottom: 20 }}>
                <label className="form-label">Password</label>
                <input
                  type="password"
                  className="form-input"
                  placeholder="Enter initial password"
                  value={teacherPassword}
                  onChange={(e) => setTeacherPassword(e.target.value)}
                  required
                />
              </div>

              <button type="submit" className="btn btn-primary" style={{ width: "100%", padding: "12px", fontWeight: 800 }} disabled={busy}>
                {busy ? "Creating Teacher..." : "Create Teacher Account"}
              </button>
            </form>

            {createdTeacherResult && (
              <div style={{ marginTop: 20, background: "rgba(0, 255, 136, 0.1)", border: "1px solid #00FF88", borderRadius: 10, padding: 14, color: "#00FF88" }}>
                <CheckCircle2 size={18} style={{ verticalAlign: "middle", marginRight: 6 }} />
                <strong>Teacher Created Successfully!</strong>
                <div style={{ fontSize: "0.85rem", color: "#ffffff", marginTop: 6 }}>
                  Email: <strong>{createdTeacherResult.email}</strong> • Dept: <strong>{createdTeacherResult.department}</strong>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* TAB 4: CREATE CLASS WITH AUTO-ENROLLMENT */}
      {activeTab === "create_class" && (
        <div style={{ maxWidth: 600, margin: "0 auto" }}>
          <div className="panel glass-panel" style={{ border: "1px solid #00E6FF", padding: 24 }}>
            <h2 style={{ fontSize: "1.3rem", fontWeight: 800, color: "#ffffff", marginBottom: 6 }}>
              <Plus size={22} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 8 }} />
              Create Class &amp; Auto-Enroll Students
            </h2>
            <p style={{ color: "#94a3b8", fontSize: "0.85rem", marginBottom: 20 }}>
              All registered students belonging to the selected Department &amp; Academic Session will be automatically enrolled upon creation.
            </p>

            <form onSubmit={handleCreateClass}>
              <div className="form-group" style={{ marginBottom: 14 }}>
                <label className="form-label">Department</label>
                <CustomSelect
                  options={DEPARTMENTS.map((d) => ({ value: d, label: d }))}
                  value={classForm.department}
                  onChange={(val) => setClassForm((prev) => ({ ...prev, department: val }))}
                />
              </div>

              <div className="form-group" style={{ marginBottom: 14 }}>
                <label className="form-label">Academic Session (Format: YYYY-YY)</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="2023-24"
                  value={classForm.academicSession}
                  onChange={(e) => setClassForm((prev) => ({ ...prev, academicSession: e.target.value }))}
                  required
                />
              </div>

              <div className="form-group" style={{ marginBottom: 14 }}>
                <label className="form-label">Year &amp; Semester</label>
                <CustomSelect
                  options={SEMESTERS.map((s) => ({ value: s, label: s }))}
                  value={classForm.semester}
                  onChange={(val) => setClassForm((prev) => ({ ...prev, semester: val }))}
                />
              </div>

              <div className="form-group" style={{ marginBottom: 14 }}>
                <label className="form-label">Subject</label>
                {availableSubjects.length === 0 ? (
                  <p style={{ color: "#94a3b8", fontSize: "0.85rem" }}>No pre-configured subjects for this department/semester.</p>
                ) : (
                  <CustomSelect
                    options={availableSubjects.map((sub) => ({ value: sub.code, label: `${sub.name} (${sub.code})` }))}
                    value={classForm.subjectCode}
                    onChange={(val) => {
                      const found = availableSubjects.find((s) => s.code === val);
                      if (found) {
                        setClassForm((prev) => ({
                          ...prev,
                          subjectCode: found.code,
                          subjectName: found.name,
                          credits: found.credits,
                        }));
                      }
                    }}
                  />
                )}
              </div>

              <div className="form-group" style={{ marginBottom: 16 }}>
                <label className="form-label">Assign Faculty / Teacher</label>
                {deptTeachers.length === 0 ? (
                  <div style={{ background: "rgba(239, 68, 68, 0.12)", border: "1px solid #ef4444", padding: 10, borderRadius: 8, color: "#ef4444", fontSize: "0.85rem" }}>
                    No teachers registered under {classForm.department}. Please create a teacher in the "Create Teacher" tab first.
                  </div>
                ) : (
                  <CustomSelect
                    options={deptTeachers.map((t) => ({ value: t.id, label: `${t.email} (${t.department})` }))}
                    value={classForm.teacherId}
                    onChange={(val) => setClassForm((prev) => ({ ...prev, teacherId: val }))}
                  />
                )}
              </div>

              {/* Auto-enrollment Alert Banner */}
              <div style={{ background: "rgba(0, 255, 136, 0.1)", border: "1px solid rgba(0, 255, 136, 0.4)", borderRadius: 10, padding: 12, marginBottom: 20 }}>
                <div style={{ color: "#00FF88", fontWeight: 700, fontSize: "0.85rem", display: "flex", alignItems: "center", gap: 6 }}>
                  <CheckCircle2 size={16} /> Auto-Enrollment Active
                </div>
                <p style={{ color: "#e2e8f0", fontSize: "0.8rem", margin: "4px 0 0" }}>
                  All students in <strong>{classForm.department}</strong> (Session: <strong>{classForm.academicSession}</strong>) will be automatically enrolled and see this class in their dashboard.
                </p>
              </div>

              <button type="submit" className="btn btn-primary" style={{ width: "100%", padding: "12px", fontWeight: 800 }} disabled={busy || !classForm.teacherId}>
                {busy ? "Creating & Auto-Enrolling..." : "Create Class & Auto-Enroll"}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* TAB 5: PASSWORD MANAGEMENT */}
      {activeTab === "passwords" && (
        <div style={{ maxWidth: 540, margin: "0 auto" }}>
          <div className="panel glass-panel" style={{ border: "1px solid #00E6FF", padding: 24 }}>
            <h2 style={{ fontSize: "1.3rem", fontWeight: 800, color: "#ffffff", marginBottom: 6 }}>
              <Lock size={22} color="#00E6FF" style={{ verticalAlign: "middle", marginRight: 8 }} />
              Admin Password Override
            </h2>
            <p style={{ color: "#94a3b8", fontSize: "0.85rem", marginBottom: 20 }}>
              Change the password for any student (enter Registration Number) or teacher (enter Email address).
            </p>

            <form onSubmit={handleResetPassword}>
              <div className="form-group" style={{ marginBottom: 16 }}>
                <label className="form-label">Student Reg No or Teacher Email</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="e.g. 2023831001 or teacher@sust.edu"
                  value={resetIdentifier}
                  onChange={(e) => setResetIdentifier(e.target.value)}
                  required
                />
              </div>

              <div className="form-group" style={{ marginBottom: 20 }}>
                <label className="form-label">New Password</label>
                <input
                  type="password"
                  className="form-input"
                  placeholder="Enter new password"
                  value={resetNewPassword}
                  onChange={(e) => setResetNewPassword(e.target.value)}
                  required
                />
              </div>

              <button type="submit" className="btn btn-primary" style={{ width: "100%", padding: "12px", fontWeight: 800 }} disabled={busy}>
                {busy ? "Updating Password..." : "Change Password"}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* END CLASS CONFIRMATION MODAL */}
      {endClassModal.open && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.85)", zIndex: 99999, display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
          <div className="panel glass-panel" style={{ width: "min(90vw, 440px)", border: "2px solid #ef4444", padding: 24, textAlign: "center" }}>
            <PowerOff size={40} color="#ef4444" style={{ margin: "0 auto 12px" }} />
            <h3 style={{ color: "#ef4444", fontSize: "1.2rem", fontWeight: 800, margin: "0 0 8px" }}>End Class &amp; Archive?</h3>
            <p style={{ color: "#e2e8f0", fontSize: "0.85rem", lineHeight: 1.5, marginBottom: 20 }}>
              Are you sure you want to end <strong>{endClassModal.cls?.code} - {endClassModal.cls?.subjectName}</strong>?
              This class will be hidden from the teacher and student active dashboards, but all records will remain safely archived in the database.
            </p>
            <div style={{ display: "flex", gap: 10, justifyContent: "center" }}>
              <button type="button" className="btn btn-secondary" onClick={() => setEndClassModal({ open: false, cls: null })}>
                Cancel
              </button>
              <button
                type="button"
                className="btn"
                style={{ background: "linear-gradient(135deg, #ef4444, #dc2626)", color: "#ffffff", fontWeight: 800, padding: "8px 20px" }}
                onClick={handleEndClass}
                disabled={busy}
              >
                Yes, End Class
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MATRIX ATTENDANCE REPORT MODAL */}
      {matrixModal.open && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.92)", zIndex: 99999, display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
          <div className="panel glass-panel" style={{ width: "min(98vw, 1100px)", maxHeight: "92vh", overflowY: "auto", border: "1px solid #00E6FF", padding: 24 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", borderBottom: "1px solid #213042", paddingBottom: 14, marginBottom: 16 }}>
              <div>
                <h2 style={{ fontSize: "1.4rem", fontWeight: 900, color: "#ffffff", margin: 0 }}>
                  Attendance Matrix Report
                </h2>
                {matrixModal.data && (
                  <p style={{ color: "#00E6FF", fontSize: "0.85rem", margin: "4px 0 0", fontWeight: 600 }}>
                    {matrixModal.data.subjectName} ({matrixModal.data.classCode}) • {matrixModal.data.department} • {matrixModal.data.academicSession}
                  </p>
                )}
              </div>
              <div style={{ display: "flex", gap: 8 }}>
                {matrixModal.data && (
                  <>
                    <a
                      href={`/api/classes/${matrixModal.data.classId}/report/csv`}
                      className="btn btn-secondary"
                      style={{ padding: "6px 12px", fontSize: "0.8rem", display: "inline-flex", alignItems: "center", gap: 6, color: "#00FF88", borderColor: "rgba(0, 255, 136, 0.4)" }}
                      download
                    >
                      <FileSpreadsheet size={14} /> Download CSV
                    </a>
                    <button
                      type="button"
                      className="btn btn-secondary"
                      style={{ padding: "6px 12px", fontSize: "0.8rem", display: "inline-flex", alignItems: "center", gap: 6, color: "#00E6FF", borderColor: "rgba(0, 230, 255, 0.4)" }}
                      onClick={() => window.print()}
                    >
                      <Printer size={14} /> Print
                    </button>
                  </>
                )}
                <button
                  type="button"
                  className="btn btn-secondary"
                  style={{ padding: "6px 10px" }}
                  onClick={() => setMatrixModal({ open: false, data: null, loading: false })}
                >
                  <X size={16} />
                </button>
              </div>
            </div>

            {matrixModal.loading || !matrixModal.data ? (
              <div style={{ textAlign: "center", padding: "40px", color: "#94a3b8" }}>Generating attendance matrix...</div>
            ) : (
              <div>
                {/* Summary Header Metrics */}
                <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: 12, marginBottom: 20 }}>
                  <div style={{ background: "#090F17", border: "1px solid #213042", padding: "10px 14px", borderRadius: 8 }}>
                    <span style={{ color: "#94a3b8", fontSize: "0.75rem", display: "block" }}>TOTAL SESSIONS</span>
                    <strong style={{ color: "#00E6FF", fontSize: "1.2rem" }}>{matrixModal.data.totalSessions}</strong>
                  </div>
                  <div style={{ background: "#090F17", border: "1px solid #213042", padding: "10px 14px", borderRadius: 8 }}>
                    <span style={{ color: "#94a3b8", fontSize: "0.75rem", display: "block" }}>TOTAL STUDENTS</span>
                    <strong style={{ color: "#ffffff", fontSize: "1.2rem" }}>{matrixModal.data.totalStudents}</strong>
                  </div>
                  <div style={{ background: "#090F17", border: "1px solid #213042", padding: "10px 14px", borderRadius: 8 }}>
                    <span style={{ color: "#94a3b8", fontSize: "0.75rem", display: "block" }}>AVERAGE ATTENDANCE</span>
                    <strong style={{ color: "#00FF88", fontSize: "1.2rem" }}>{matrixModal.data.averageAttendancePercentage}%</strong>
                  </div>
                  <div style={{ background: "#090F17", border: "1px solid #213042", padding: "10px 14px", borderRadius: 8 }}>
                    <span style={{ color: "#94a3b8", fontSize: "0.75rem", display: "block" }}>TEACHER</span>
                    <strong style={{ color: "#ffffff", fontSize: "0.95rem" }}>{matrixModal.data.teacherName}</strong>
                  </div>
                </div>

                {/* Matrix Table */}
                <div style={{ overflowX: "auto", border: "1px solid #213042", borderRadius: 10 }}>
                  <table className="table" style={{ width: "100%", fontSize: "0.82rem", textAlign: "center", borderCollapse: "collapse" }}>
                    <thead>
                      <tr style={{ background: "#0D1520", borderBottom: "2px solid #00E6FF" }}>
                        <th style={{ padding: "10px 12px", textAlign: "left", color: "#00E6FF", position: "sticky", left: 0, background: "#0D1520", zIndex: 2 }}>
                          Student Reg No
                        </th>
                        {matrixModal.data.sessions.map((sess, sIdx) => {
                          const dateObj = new Date(sess.startedAt);
                          return (
                            <th key={sess.sessionId} style={{ padding: "8px 10px", fontSize: "0.75rem", color: "#ffffff", minWidth: 95 }}>
                              <div>{dateObj.toLocaleDateString()}</div>
                              <div style={{ color: "#94a3b8", fontSize: "0.7rem" }}>{dateObj.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}</div>
                            </th>
                          );
                        })}
                        <th style={{ padding: "8px 12px", color: "#00FF88", minWidth: 80 }}>Total</th>
                        <th style={{ padding: "8px 12px", color: "#00FF88", minWidth: 80 }}>%</th>
                      </tr>
                    </thead>
                    <tbody>
                      {matrixModal.data.studentRows.map((row, rIdx) => (
                        <tr key={row.registrationNo} style={{ borderBottom: "1px solid #213042", background: rIdx % 2 === 0 ? "rgba(255,255,255,0.01)" : "transparent" }}>
                          <td style={{ padding: "8px 12px", textAlign: "left", fontWeight: 700, fontFamily: "monospace", color: "#ffffff", position: "sticky", left: 0, background: "#090F17", zIndex: 1 }}>
                            {row.registrationNo}
                          </td>
                          {row.attendance.map((present, aIdx) => (
                            <td key={aIdx} style={{ padding: "8px", fontWeight: 800, color: present ? "#00FF88" : "#ef4444" }}>
                              {present ? "P" : "A"}
                            </td>
                          ))}
                          <td style={{ padding: "8px 12px", fontWeight: 800, color: "#ffffff" }}>{row.totalAttended}</td>
                          <td style={{ padding: "8px 12px", fontWeight: 800, color: row.percentage >= 75 ? "#00FF88" : row.percentage >= 50 ? "#fbbf24" : "#ef4444" }}>
                            {row.percentage}%
                          </td>
                        </tr>
                      ))}
                      {/* Summary Row */}
                      <tr style={{ background: "#0D1520", borderTop: "2px solid #213042", fontWeight: 800 }}>
                        <td style={{ padding: "10px 12px", textAlign: "left", color: "#00E6FF", position: "sticky", left: 0, background: "#0D1520" }}>
                          Total Present
                        </td>
                        {matrixModal.data.sessionAttendanceCounts.map((count, cIdx) => (
                          <td key={cIdx} style={{ padding: "8px", color: "#00FF88" }}>
                            {count}
                          </td>
                        ))}
                        <td style={{ padding: "8px 12px" }}>-</td>
                        <td style={{ padding: "8px 12px" }}>-</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
