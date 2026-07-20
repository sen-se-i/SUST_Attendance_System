import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../lib/AuthContext";

export function ProtectedRoute({ role }) {
  const { isAuthenticated, user } = useAuth();

  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (role && user.role !== role) {
    return <Navigate to={user.role === "ADMIN" ? "/teacher" : "/student"} replace />;
  }
  return <Outlet />;
}
