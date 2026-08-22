import { useState } from "react";
import { Navigate } from "react-router-dom";
import { LogIn, LoaderCircle } from "lucide-react";
import { useAuth } from "../lib/AuthContext";
import { useToast } from "../lib/ToastContext";
import { api, ApiError, setToken } from "../lib/api";

const initialLogin = { email: "", password: "" };

export default function AuthPage() {
  const { login, isAuthenticated, user } = useAuth();
  const notify = useToast();
  const [loginForm, setLoginForm] = useState(initialLogin);
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

  return (
    <div style={{ maxWidth: "400px", margin: "40px auto 0" }}>
      <form className="panel" onSubmit={handleLogin}>
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
        <button type="submit" className="btn btn-primary" style={{ width: "100%" }} disabled={busy}>
          {busy ? (
            <>
              <LoaderCircle size={16} className="spin" /> Signing in…
            </>
          ) : (
            "Login"
          )}
        </button>
      </form>
    </div>
  );
}

