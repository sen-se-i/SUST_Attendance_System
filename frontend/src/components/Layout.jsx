import { LogOut } from "lucide-react";
import { useAuth } from "../lib/AuthContext";

export function Layout({ children }) {
  const { user, logout } = useAuth();

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand">
          <div>
            <h1>SWE Attendance System</h1>
            <p className="subtitle">
              {user ? `${user.role === "ADMIN" ? "Teacher" : "Student"} Console` : "GPS Location Attendance"}
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

