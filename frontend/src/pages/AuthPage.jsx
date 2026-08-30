import { useState } from "react";
import { Navigate } from "react-router-dom";
import { LogIn, LoaderCircle, Shield } from "lucide-react";
import { useAuth } from "../lib/AuthContext";
import { useToast } from "../lib/ToastContext";
import { ApiError } from "../lib/api";

const initialLogin = { email: "", password: "" };

export default function AuthPage() {
  const { login, isAuthenticated, user } = useAuth();
  const notify = useToast();
  const [loginForm, setLoginForm] = useState(initialLogin);
  const [busy, setBusy] = useState(false);

  if (isAuthenticated) {
    if (user.role === "ADMIN") return <Navigate to="/admin" replace />;
    if (user.role === "TEACHER") return <Navigate to="/teacher" replace />;
    return <Navigate to="/student" replace />;
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
    <div style={{ maxWidth: "420px", margin: "40px auto 0" }}>
      <form className="panel glass-panel" style={{ border: "1px solid #213042", padding: "28px" }} onSubmit={handleLogin}>
        <div style={{ textAlign: "center", marginBottom: 20 }}>
          <h2 style={{ fontSize: "1.4rem", fontWeight: 900, color: "#ffffff", margin: "0 0 6px" }}>
            <LogIn size={20} style={{ verticalAlign: "middle", marginRight: 6, color: "#00E6FF" }} />
            System Login
          </h2>
          <p style={{ color: "#94a3b8", fontSize: "0.82rem", margin: 0 }}>
            Enter your Registration Number (Students) or Email Address (Faculty / Admin).
          </p>
        </div>

        <div className="form-group" style={{ marginBottom: 16 }}>
          <label className="form-label" htmlFor="login-email">
            Registration No (Student) / Email (Faculty &amp; Admin)
          </label>
          <input
            id="login-email"
            className="form-input"
            type="text"
            required
            autoComplete="username"
            placeholder="e.g. 2023831001 or admin@example.com"
            value={loginForm.email}
            onChange={(e) => setLoginForm((f) => ({ ...f, email: e.target.value }))}
          />
        </div>

        <div className="form-group" style={{ marginBottom: 20 }}>
          <label className="form-label" htmlFor="login-password">
            Password
          </label>
          <input
            id="login-password"
            className="form-input"
            type="password"
            required
            autoComplete="current-password"
            placeholder="Enter your password"
            value={loginForm.password}
            onChange={(e) => setLoginForm((f) => ({ ...f, password: e.target.value }))}
          />
        </div>

        {}
        <div style={{ marginBottom: 20 }}>
          <span style={{ color: "#94a3b8", fontSize: "0.75rem", fontWeight: 700, display: "block", marginBottom: 8 }}>
            QUICK DEMO ACCOUNTS:
          </span>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "8px" }}>
            <button
              type="button"
              className="btn btn-secondary"
              style={{ fontSize: "0.75rem", padding: "6px 8px", borderColor: "#00E6FF", color: "#00E6FF" }}
              onClick={() => setLoginForm({ email: "admin@example.com", password: "password" })}
            >
              👑 Admin Demo
            </button>
            <button
              type="button"
              className="btn btn-secondary"
              style={{ fontSize: "0.75rem", padding: "6px 8px", borderColor: "#00FF88", color: "#00FF88" }}
              onClick={() => setLoginForm({ email: "teacher@example.com", password: "password" })}
            >
              👨‍🏫 Teacher Demo
            </button>
            <button
              type="button"
              className="btn btn-secondary"
              style={{ fontSize: "0.75rem", padding: "6px 8px" }}
              onClick={() => setLoginForm({ email: "2023831001", password: "2023831001" })}
            >
              🎓 Student Demo
            </button>
          </div>
        </div>

        <button type="submit" className="btn btn-primary" style={{ width: "100%", padding: "12px", fontWeight: 800 }} disabled={busy}>
          {busy ? (
            <>
              <LoaderCircle size={16} className="spin" /> Signing in…
            </>
          ) : (
            "Sign In"
          )}
        </button>
      </form>
    </div>
  );
}
