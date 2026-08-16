import { useState } from "react";
import { Menu, User } from "lucide-react";
import { useAuth } from "../lib/AuthContext";
import { SideDrawer } from "./SideDrawer";

export function Layout({ children }) {
  const { user } = useAuth();
  const [drawerOpen, setDrawerOpen] = useState(false);

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand">
          <img src="/logo.png" alt="SWE Attendance System Logo" style={{ width: 32, height: 32, objectFit: "contain" }} />
          <div>
            <h1>SWE Attendance System</h1>
            <p className="subtitle">
              {user ? `${user.role === "ADMIN" ? "Teacher" : "Student"} console` : "GPS Location Geofence Attendance"}
            </p>
          </div>
        </div>
        {user && (
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => setDrawerOpen(true)}
            style={{ display: "flex", alignItems: "center", gap: 8, borderColor: "#00E6FF", color: "#00E6FF" }}
          >
            <Menu size={18} /> Menu
          </button>
        )}
      </header>
      {user && <SideDrawer isOpen={drawerOpen} onClose={() => setDrawerOpen(false)} />}
      <main className="app-main">{children}</main>
    </div>
  );
}

