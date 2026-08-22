import { useState } from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider, useAuth } from "./lib/AuthContext";
import { ToastProvider } from "./lib/ToastContext";
import { Layout } from "./components/Layout";
import { ProtectedRoute } from "./components/ProtectedRoute";
import AuthPage from "./pages/AuthPage";
import TeacherDashboard from "./pages/TeacherDashboard";
import TeacherClassDetailPage from "./pages/TeacherClassDetailPage";
import TeacherSessionDetailPage from "./pages/TeacherSessionDetailPage";
import StudentDashboard from "./pages/StudentDashboard";
import StudentClassDetailPage from "./pages/StudentClassDetailPage";
import "./App.css";

function RoleRedirect() {
  const { user } = useAuth();
  return <Navigate to={user.role === "ADMIN" ? "/teacher" : "/student"} replace />;
}

function AppRoutes() {
  return (
    <Layout>
      <Routes>
        <Route path="/login" element={<AuthPage />} />
        <Route element={<ProtectedRoute role="ADMIN" />}>
          <Route path="/teacher" element={<TeacherDashboard />} />
          <Route path="/teacher/class/:classId" element={<TeacherClassDetailPage />} />
          <Route path="/teacher/class/:classId/session/:sessionId" element={<TeacherSessionDetailPage />} />
        </Route>
        <Route element={<ProtectedRoute role="STUDENT" />}>
          <Route path="/student" element={<StudentDashboard />} />
          <Route path="/student/class/:classId" element={<StudentClassDetailPage />} />
        </Route>
        <Route element={<ProtectedRoute />}>
          <Route path="/" element={<RoleRedirect />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Layout>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <ToastProvider>
        <AppRoutes />
      </ToastProvider>
    </AuthProvider>
  );
}


