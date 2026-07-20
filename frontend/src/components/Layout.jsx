import { LogOut, ScanLine } from "lucide-react";
import { useAuth } from "../lib/AuthContext";

export function Layout({ children }) {
  const { user, logout } = useAuth();

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand">
          <ScanLine size={26} className="brand-icon" />
          <div>
            <h1>JARVIS-ATT</h1>
            <p className="subtitle">
              {user ? `${user.role === "ADMIN" ? "Teacher" : "Student"} console` : "Rotating QR attendance"}
            </p>
          </div>
        </div>
        {user && (
          <button type="button" className="btn btn-secondary" onClick={logout}>
            <LogOut size={16} /> Logout
          </button>
        )}
      </header>
      <main className="app-main">{children}</main>
    </div>
  );
}
