import { LogOut, MapPin } from "lucide-react";
import { useAuth } from "../lib/AuthContext";

export function Layout({ children }) {
  const { user, logout } = useAuth();

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand">
          <img src="/logo.png" alt="SWE-Attendance Logo" style={{ width: 32, height: 32, objectFit: "contain" }} />
          <div>
            <h1>SWE-Attendance</h1>
            <p className="subtitle">
              {user ? `${user.role === "ADMIN" ? "Teacher" : "Student"} console` : "GPS Location Geofence Attendance"}
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
