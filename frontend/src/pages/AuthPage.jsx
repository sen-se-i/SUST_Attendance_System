import { useState } from "react";
import { Navigate } from "react-router-dom";
import { LogIn, UserPlus, LoaderCircle, KeyRound, X } from "lucide-react";
import { useAuth } from "../lib/AuthContext";
import { useToast } from "../lib/ToastContext";
import { api, ApiError, setToken } from "../lib/api";

const initialLogin = { email: "", password: "" };
const initialRegister = { email: "", password: "", role: "STUDENT", registrationNo: "" };

export default function AuthPage() {
  const { login, register, isAuthenticated, user } = useAuth();
  const notify = useToast();
  const [loginForm, setLoginForm] = useState(initialLogin);
  const [registerForm, setRegisterForm] = useState(initialRegister);
  const [busy, setBusy] = useState(false);

  const [showForgotModal, setShowForgotModal] = useState(false);
  const [forgotRegNo, setForgotRegNo] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [resetBusy, setResetBusy] = useState(false);

  if (isAuthenticated) {
    return <Navigate to={user.role === "ADMIN" ? "/teacher" : "/student"} replace />;
  }

  async function handleLogin(event) {
    event.preventDefault();
    setBusy(true);
    try {
      await login(loginForm);
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Login failed", "danger");
    } finally {
      setBusy(false);
    }
  }

  async function handleRegister(event) {
    event.preventDefault();
    setBusy(true);
    try {
      await register(registerForm);
      notify("Account created.", "success");
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Registration failed", "danger");
    } finally {
      setBusy(false);
    }
  }

  async function handleResetPassword(e) {
    e.preventDefault();
    if (!forgotRegNo.trim() || !newPassword.trim()) return;
    setResetBusy(true);
    try {
      await api("/api/auth/reset-password", {
        method: "POST",
        body: JSON.stringify({ registrationNo: forgotRegNo.trim(), newPassword: newPassword.trim() }),
      });
      notify("Password reset successfully! Device lock cleared. You can now login.", "success");
      setToken(null);
      setShowForgotModal(false);
      setLoginForm((prev) => ({ ...prev, password: newPassword }));
      setForgotRegNo("");
      setNewPassword("");
    } catch (error) {
      notify(error instanceof ApiError ? error.message : "Password reset failed", "danger");
    } finally {
      setResetBusy(false);
    }
  }

  return (
    <div className="auth-grid">
      <form className="panel glass-panel" onSubmit={handleLogin}>
        <h2>
          <LogIn size={20} /> Login
        </h2>
        <div className="form-group">
          <label className="form-label" htmlFor="login-email">
            Email / Student Account
          </label>
          <input
            id="login-email"
            className="form-input"
            type="email"
            required
            autoComplete="email"
            value={loginForm.email}
            onChange={(e) => setLoginForm((f) => ({ ...f, email: e.target.value }))}
          />
        </div>
        <div className="form-group">
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <label className="form-label" htmlFor="login-password">
              Password
            </label>
            <button
              type="button"
              style={{ background: "none", border: "none", color: "#00E6FF", fontSize: "0.8rem", cursor: "pointer", fontWeight: 700 }}
              onClick={() => setShowForgotModal(true)}
            >
              Forgot Password?
            </button>
          </div>
          <input
            id="login-password"
            className="form-input"
            type="password"
            required
            autoComplete="current-password"
            value={loginForm.password}
            onChange={(e) => setLoginForm((f) => ({ ...f, password: e.target.value }))}
          />
        </div>
        <div style={{ display: "flex", gap: "8px", marginBottom: "16px", flexWrap: "wrap" }}>
          <button
            type="button"
            className="btn btn-secondary"
            style={{ fontSize: "0.8rem", padding: "6px 12px" }}
            onClick={() => setLoginForm({ email: "teacher@example.com", password: "password" })}
          >
            Teacher Demo
          </button>
          <button
            type="button"
            className="btn btn-secondary"
            style={{ fontSize: "0.8rem", padding: "6px 12px" }}
            onClick={() => setLoginForm({ email: "ch.wixard@student.sust.edu", password: "password" })}
          >
            Student Demo
          </button>
        </div>
        <button type="submit" className="btn btn-primary" disabled={busy}>
          {busy ? (
            <>
              <LoaderCircle size={16} className="spin" /> Signing in…
            </>
          ) : (
            "Login"
          )}
        </button>
      </form>

      <form className="panel glass-panel" onSubmit={handleRegister}>
        <h2>
          <UserPlus size={20} /> Create Account
        </h2>
        <div className="form-group">
          <label className="form-label" htmlFor="reg-email">
            Email
          </label>
          <input
            id="reg-email"
            className="form-input"
            type="email"
            required
            autoComplete="email"
            value={registerForm.email}
            onChange={(e) => setRegisterForm((f) => ({ ...f, email: e.target.value }))}
          />
        </div>
        <div className="form-group">
          <label className="form-label" htmlFor="reg-password">
            Password
          </label>
          <input
            id="reg-password"
            className="form-input"
            type="password"
            required
            minLength={6}
            value={registerForm.password}
            onChange={(e) => setRegisterForm((f) => ({ ...f, password: e.target.value }))}
          />
        </div>
        <div className="form-group">
          <label className="form-label" htmlFor="reg-role">
            Role
          </label>
          <select
            id="reg-role"
            className="form-input form-select"
            value={registerForm.role}
            onChange={(e) => setRegisterForm((f) => ({ ...f, role: e.target.value }))}
          >
            <option value="STUDENT">Student</option>
            <option value="ADMIN">Teacher</option>
          </select>
        </div>
        {registerForm.role === "STUDENT" && (
          <div className="form-group">
            <label className="form-label" htmlFor="reg-regno">
              Registration No
            </label>
            <input
              id="reg-regno"
              className="form-input"
              placeholder="Students only"
              value={registerForm.registrationNo}
              onChange={(e) => setRegisterForm((f) => ({ ...f, registrationNo: e.target.value }))}
            />
          </div>
        )}
        <button type="submit" className="btn btn-primary" disabled={busy}>
          {busy ? (
            <>
              <LoaderCircle size={16} className="spin" /> Creating account…
            </>
          ) : (
            "Register"
          )}
        </button>
      </form>

      {showForgotModal && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.85)", zIndex: 99999, display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
          <div className="panel glass-panel" style={{ width: "min(90vw, 420px)", border: "1px solid #00E6FF", position: "relative" }}>
            <button
              type="button"
              onClick={() => setShowForgotModal(false)}
              style={{ position: "absolute", top: 16, right: 16, background: "none", border: "none", color: "#94a3b8", cursor: "pointer" }}
            >
              <X size={20} />
            </button>

            <h3 style={{ fontSize: "1.3rem", color: "#ffffff", fontWeight: 800, marginBottom: 8, display: "flex", alignItems: "center", gap: 8 }}>
              <KeyRound size={20} color="#00E6FF" /> Reset Account Password
            </h3>
            <p style={{ color: "#94a3b8", fontSize: "0.85rem", marginBottom: 16 }}>
              Enter your Registration Number (e.g. <code>2023831061</code>) or Email address to set a new password and clear any device lock.
            </p>

            <form onSubmit={handleResetPassword}>
              <div className="form-group" style={{ marginBottom: 14 }}>
                <label className="form-label">Registration No or Email</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="e.g. 2023831061"
                  value={forgotRegNo}
                  onChange={(e) => setForgotRegNo(e.target.value)}
                  required
                />
              </div>

              <div className="form-group" style={{ marginBottom: 20 }}>
                <label className="form-label">New Password</label>
                <input
                  type="password"
                  className="form-input"
                  placeholder="Enter new password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  minLength={6}
                  required
                />
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: 12 }}>
                <button type="button" className="btn btn-secondary" onClick={() => setShowForgotModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={resetBusy}>
                  {resetBusy ? "Resetting..." : "Reset Password"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

