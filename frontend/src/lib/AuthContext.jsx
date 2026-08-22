import { createContext, useCallback, useContext, useMemo, useState } from "react";
import { api, getToken, setToken } from "./api";
import { getDeviceInstallId } from "./deviceId";

const USER_KEY = "jarvisatt.user";
const AuthContext = createContext(null);

function readStoredUser() {
  try {
    return JSON.parse(localStorage.getItem(USER_KEY) || "null");
  } catch {
    return null;
  }
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(readStoredUser);
  const [token, setTokenState] = useState(getToken);

  const applyAuth = useCallback((auth) => {
    const nextUser = { userId: auth.userId, email: auth.email, role: auth.role, registrationNo: auth.registrationNo };
    setToken(auth.token);
    localStorage.setItem(USER_KEY, JSON.stringify(nextUser));
    setTokenState(auth.token);
    setUser(nextUser);
  }, []);

  const login = useCallback(
    (credentials) => {
      const deviceInstallId = getDeviceInstallId();
      const body = { ...credentials, deviceInstallId };
      return api("/api/auth/login", { method: "POST", body: JSON.stringify(body) }).then(applyAuth);
    },
    [applyAuth],
  );

  const register = useCallback(
    (payload) => {
      const deviceInstallId = getDeviceInstallId();
      const body = { ...payload, deviceInstallId };
      return api("/api/auth/register", { method: "POST", body: JSON.stringify(body) }).then(applyAuth);
    },
    [applyAuth],
  );

  const logout = useCallback(() => {
    setToken(null);
    localStorage.removeItem(USER_KEY);
    setTokenState(null);
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({ user, token, login, register, logout, isAuthenticated: Boolean(token && user) }),
    [user, token, login, register, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}

