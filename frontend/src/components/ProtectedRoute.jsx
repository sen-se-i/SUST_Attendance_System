import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";

export function ProtectedRoute({ role }) {
  const { isAuthenticated, user } = useAuth();

  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (role && user.role !== role) {
    if (user.role === "ADMIN") return <Navigate to="/admin" replace />;
    if (user.role === "TEACHER") return <Navigate to="/teacher" replace />;
    return <Navigate to="/student" replace />;
  }
  return <Outlet />;
}

