import { useState, useEffect } from "react";
import { X, User, LogOut, Mail, Hash, BookOpen } from "lucide-react";
import { useAuth } from "../lib/AuthContext";
import { api } from "../lib/api";

export function SideDrawer({ isOpen, onClose }) {
  const { user, logout } = useAuth();
  const [profile, setProfile] = useState(null);
  const [showProfileModal, setShowProfileModal] = useState(false);

  useEffect(() => {
    if (isOpen) {
      api("/api/auth/me")
        .then((data) => setProfile(data))
        .catch(() => {
          setProfile({
            email: user?.email || "user@su.edu.bd",
            role: user?.role || "STUDENT",
            registrationNo: user?.registrationNo || "N/A",
            department: "Software Engineering",
          });
        });
    }
  }, [isOpen, user]);

  if (!isOpen) return null;

  const currentUser = profile || user || {};
  const emailDisplay = currentUser.email || "User Account";
  const userRole = currentUser.role || user?.role || "USER";
  const regNo = currentUser.registrationNo || user?.registrationNo || "N/A";
  const initial = emailDisplay.charAt(0).toUpperCase();

  return (
    <>
      {/* Backdrop Overlay */}
      <div
        onClick={onClose}
        style={{
          position: "fixed",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          width: "100vw",
          height: "100vh",
          background: "rgba(0, 0, 0, 0.85)",
          backdropFilter: "blur(6px)",
          zIndex: 99990,
        }}
      />

      {/* Sliding Side Drawer Panel */}
      <div
        style={{
          position: "fixed",
          top: 0,
          right: 0,
          bottom: 0,
          width: "min(80vw, 300px)",
          height: "100vh",
          background: "#090F17",
          borderLeft: "1px solid #00E6FF",
          boxShadow: "-10px 0 40px rgba(0, 0, 0, 0.9)",
          zIndex: 99995,
          display: "flex",
          flexDirection: "column",
          padding: "24px 20px",
          boxSizing: "border-box",
        }}
      >
        {/* Drawer Header */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            borderBottom: "1px solid #213042",
            paddingBottom: 16,
            marginBottom: 24,
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div
              style={{
                width: 42,
                height: 42,
                borderRadius: "50%",
                background: "linear-gradient(135deg, #00E6FF, #00FF88)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#000000",
                fontWeight: 900,
                fontSize: "1.1rem",
              }}
            >
              {initial}
            </div>
            <div>
              <div style={{ color: "#ffffff", fontWeight: 800, fontSize: "0.95rem" }}>
                {emailDisplay.split("@")[0]}
              </div>
              <span
                style={{
                  display: "inline-block",
                  padding: "2px 8px",
                  borderRadius: 4,
                  background: "rgba(0, 230, 255, 0.15)",
                  color: "#00E6FF",
                  border: "1px solid #00E6FF",
                  fontSize: "0.65rem",
                  fontWeight: 800,
                  letterSpacing: "0.5px",
                  marginTop: 3,
                }}
              >
                {userRole}
              </span>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            style={{
              background: "transparent",
              border: "none",
              color: "#94a3b8",
              cursor: "pointer",
              padding: 4,
            }}
          >
            <X size={22} />
          </button>
        </div>

        {/* Menu Items Area */}
        <div style={{ display: "flex", flexDirection: "column", gap: 12, flex: 1 }}>
          <button
            type="button"
            onClick={() => setShowProfileModal(true)}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 12,
              padding: "14px 16px",
              background: "rgba(0, 230, 255, 0.08)",
              border: "1px solid rgba(0, 230, 255, 0.3)",
              borderRadius: 12,
              color: "#ffffff",
              fontWeight: 700,
              cursor: "pointer",
              textAlign: "left",
              fontSize: "0.95rem",
            }}
          >
            <User size={20} color="#00E6FF" />
            <span>My Profile</span>
          </button>
        </div>

        {/* Bottom Logout Area */}
        <div style={{ borderTop: "1px solid #213042", paddingTop: 16, marginTop: "auto" }}>
          <button
            type="button"
            onClick={() => {
              onClose();
              logout();
            }}
            style={{
              width: "100%",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 10,
              padding: "14px",
              background: "rgba(239, 68, 68, 0.12)",
              border: "1px solid rgba(239, 68, 68, 0.4)",
              borderRadius: 12,
              color: "#ef4444",
              fontWeight: 800,
              cursor: "pointer",
              fontSize: "0.95rem",
            }}
          >
            <LogOut size={18} /> Logout Account
          </button>
        </div>
      </div>

      {/* Clean User Profile Modal */}
      {showProfileModal && (
        <div
          style={{
            position: "fixed",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            width: "100vw",
            height: "100vh",
            background: "rgba(0, 0, 0, 0.88)",
            backdropFilter: "blur(8px)",
            zIndex: 100050,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: 16,
            boxSizing: "border-box",
            overflowY: "auto",
          }}
        >
          <div
            style={{
              width: "min(90vw, 400px)",
              maxHeight: "85vh",
              overflowY: "auto",
              background: "#0D1520",
              border: "1px solid #00E6FF",
              borderRadius: 16,
              padding: 24,
              boxShadow: "0 0 40px rgba(0, 230, 255, 0.3)",
              position: "relative",
              boxSizing: "border-box",
            }}
          >
            {/* Top Close Icon */}
            <button
              type="button"
              onClick={() => setShowProfileModal(false)}
              style={{
                position: "absolute",
                top: 16,
                right: 16,
                background: "transparent",
                border: "none",
                color: "#94a3b8",
                cursor: "pointer",
              }}
            >
              <X size={20} />
            </button>

            {/* Profile Avatar Header */}
            <div style={{ textAlign: "center", marginBottom: 20 }}>
              <div
                style={{
                  width: 64,
                  height: 64,
                  borderRadius: "50%",
                  background: "linear-gradient(135deg, #00E6FF, #00FF88)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "#000000",
                  fontWeight: 900,
                  fontSize: "1.8rem",
                  margin: "0 auto 12px",
                  boxShadow: "0 0 20px rgba(0, 230, 255, 0.4)",
                }}
              >
                {initial}
              </div>
              <h3 style={{ color: "#ffffff", fontSize: "1.3rem", fontWeight: 800, margin: 0 }}>
                {emailDisplay.split("@")[0]}
              </h3>
              <span
                style={{
                  display: "inline-block",
                  padding: "3px 10px",
                  borderRadius: 6,
                  background: "rgba(0, 255, 136, 0.15)",
                  color: "#00FF88",
                  border: "1px solid #00FF88",
                  fontSize: "0.75rem",
                  fontWeight: 800,
                  marginTop: 6,
                }}
              >
                {userRole} ACCOUNT
              </span>
            </div>

            {/* Profile Field Cards */}
            <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div
                style={{
                  background: "#090F17",
                  padding: "12px 16px",
                  borderRadius: 10,
                  border: "1px solid #213042",
                }}
              >
                <span
                  style={{
                    color: "#94a3b8",
                    fontSize: "0.75rem",
                    display: "flex",
                    alignItems: "center",
                    gap: 6,
                    fontWeight: 700,
                  }}
                >
                  <Mail size={14} color="#00E6FF" /> EMAIL ADDRESS
                </span>
                <span
                  style={{
                    color: "#ffffff",
                    fontWeight: 700,
                    fontSize: "0.95rem",
                    display: "block",
                    marginTop: 4,
                    wordBreak: "break-all",
                  }}
                >
                  {emailDisplay}
                </span>
              </div>

              {userRole === "STUDENT" && (
                <div
                  style={{
                    background: "#090F17",
                    padding: "12px 16px",
                    borderRadius: 10,
                    border: "1px solid #213042",
                  }}
                >
                  <span
                    style={{
                      color: "#94a3b8",
                      fontSize: "0.75rem",
                      display: "flex",
                      alignItems: "center",
                      gap: 6,
                      fontWeight: 700,
                    }}
                  >
                    <Hash size={14} color="#00FF88" /> REGISTRATION NUMBER
                  </span>
                  <span
                    style={{
                      color: "#00FF88",
                      fontWeight: 900,
                      fontSize: "1.1rem",
                      fontFamily: "monospace",
                      display: "block",
                      marginTop: 4,
                    }}
                  >
                    {regNo}
                  </span>
                </div>
              )}

              <div
                style={{
                  background: "#090F17",
                  padding: "12px 16px",
                  borderRadius: 10,
                  border: "1px solid #213042",
                }}
              >
                <span
                  style={{
                    color: "#94a3b8",
                    fontSize: "0.75rem",
                    display: "flex",
                    alignItems: "center",
                    gap: 6,
                    fontWeight: 700,
                  }}
                >
                  <BookOpen size={14} color="#00E6FF" /> DEPARTMENT
                </span>
                <span
                  style={{
                    color: "#00E6FF",
                    fontWeight: 700,
                    fontSize: "0.95rem",
                    display: "block",
                    marginTop: 4,
                  }}
                >
                  {currentUser.department || "Software Engineering"}
                </span>
              </div>
            </div>

            {/* Modal Bottom Actions */}
            <div style={{ textAlign: "right", marginTop: 24 }}>
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => setShowProfileModal(false)}
                style={{ padding: "8px 18px", fontSize: "0.9rem" }}
              >
                Close Profile
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
