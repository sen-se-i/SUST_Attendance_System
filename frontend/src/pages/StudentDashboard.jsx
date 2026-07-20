import { useCallback, useEffect, useState } from "react";
import { CircleCheckBig, School } from "lucide-react";
import { api, ApiError } from "../lib/api";
import { useToast } from "../lib/ToastContext";
import { useAuth } from "../lib/AuthContext";
import { getDeviceInstallId } from "../lib/deviceId";
import { AttendanceTable } from "../components/AttendanceTable";
import { ScannerPanel } from "../components/ScannerPanel";

const initialJoinForm = { classCode: "", registrationNo: "" };

export default function StudentDashboard() {
  const { user } = useAuth();
  const notify = useToast();
  const [joinForm, setJoinForm] = useState(() => ({ ...initialJoinForm, registrationNo: user?.registrationNo || "" }));
  const [qrPayload, setQrPayload] = useState("");
  const [deviceInstallId, setDeviceInstallId] = useState(getDeviceInstallId);
  const [attendance, setAttendance] = useState([]);
  const [busy, setBusy] = useState(false);

  const loadAttendance = useCallback(async () => {
    try {
      setAttendance(await api("/api/attendance/me"));
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to load attendance", "danger");
    }
  }, [notify]);

  useEffect(() => {
    loadAttendance();
  }, [loadAttendance]);

  async function handleJoin(event) {
    event.preventDefault();
    setBusy(true);
    try {
      await api("/api/classes/join", { method: "POST", body: JSON.stringify(joinForm) });
      notify("Class joined.", "success");
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to join class", "danger");
    } finally {
      setBusy(false);
    }
  }

  async function handleVerify(event) {
    event.preventDefault();
    if (!qrPayload || !deviceInstallId) return;
    setBusy(true);
    try {
      await api("/api/attendance/verify", {
        method: "POST",
        body: JSON.stringify({ qrPayload, deviceInstallId }),
      });
      setQrPayload("");
      notify("Attendance marked.", "success");
      await loadAttendance();
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Failed to mark attendance", "danger");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="student-grid">
      <form className="panel glass-panel" onSubmit={handleJoin}>
        <h2>
          <School size={18} /> Join Class
        </h2>
        <div className="form-group">
          <label className="form-label" htmlFor="classCode">
            Class Code
          </label>
          <input
            id="classCode"
            className="form-input"
            maxLength={6}
            required
            placeholder="8K2P0X"
            value={joinForm.classCode}
            onChange={(e) => setJoinForm((f) => ({ ...f, classCode: e.target.value.toUpperCase() }))}
          />
        </div>
        <div className="form-group">
          <label className="form-label" htmlFor="registrationNo">
            Registration No
          </label>
          <input
            id="registrationNo"
            className="form-input"
            required
            value={joinForm.registrationNo}
            onChange={(e) => setJoinForm((f) => ({ ...f, registrationNo: e.target.value }))}
          />
        </div>
        <button type="submit" className="btn btn-primary" disabled={busy}>
          Join
        </button>
      </form>

      <div className="panel glass-panel scanner-panel">
        <ScannerPanel onScanned={setQrPayload} />
        <form onSubmit={handleVerify}>
          <div className="form-group">
            <label className="form-label" htmlFor="qrPayload">
              QR Payload
            </label>
            <textarea
              id="qrPayload"
              className="form-input"
              rows={5}
              required
              placeholder="Camera fills this automatically, or paste here"
              value={qrPayload}
              onChange={(e) => setQrPayload(e.target.value)}
            />
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="deviceInstallId">
              Device Install ID
            </label>
            <input
              id="deviceInstallId"
              className="form-input"
              required
              value={deviceInstallId}
              onChange={(e) => setDeviceInstallId(e.target.value)}
            />
          </div>
          <button type="submit" className="btn btn-primary" disabled={busy}>
            <CircleCheckBig size={16} /> Mark Present
          </button>
        </form>
      </div>

      <div className="panel glass-panel">
        <h2>My Attendance</h2>
        <AttendanceTable rows={attendance} emptyLabel="No attendance records yet." showSubject />
      </div>
    </div>
  );
}
