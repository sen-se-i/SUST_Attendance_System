import { useState } from "react";
import { Navigate } from "react-router-dom";
import { LogIn, UserPlus, LoaderCircle } from "lucide-react";
import { useAuth } from "../lib/AuthContext";
import { useToast } from "../lib/ToastContext";
import { ApiError } from "../lib/api";

const initialLogin = { email: "", password: "" };
const initialRegister = { email: "", password: "", role: "STUDENT", registrationNo: "" };

export default function AuthPage() {
  const { login, register, isAuthenticated, user } = useAuth();
  const notify = useToast();
  const [loginForm, setLoginForm] = useState(initialLogin);
  const [registerForm, setRegisterForm] = useState(initialRegister);
  const [busy, setBusy] = useState(false);

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

  return (
    <div className="auth-grid">
      <form className="panel glass-panel" onSubmit={handleLogin}>
        <h2>
          <LogIn size={20} /> Login
        </h2>
        <div className="form-group">
          <label className="form-label" htmlFor="login-email">
            Email
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
          <label className="form-label" htmlFor="login-password">
            Password
          </label>
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
    </div>
  );
}
