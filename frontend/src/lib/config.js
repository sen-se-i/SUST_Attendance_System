const LOCAL_LAN_URL = "http://10.100.94.65:8080";
const RENDER_BACKEND_URL = "https://jarvis-att.onrender.com";

export function getApiBaseUrl() {
  const saved = localStorage.getItem("jarvisatt.api_url");
  if (saved) return saved.replace(/\/$/, "");

  if (import.meta.env.VITE_API_BASE_URL) {
    return import.meta.env.VITE_API_BASE_URL.replace(/\/$/, "");
  }

  // Capacitor native shell or local testing
  if (window.Capacitor || window.location.protocol === "file:" || window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1") {
    return LOCAL_LAN_URL;
  }

  return RENDER_BACKEND_URL.replace(/\/$/, "");
}

export const API_BASE_URL = getApiBaseUrl();

export function wsBaseUrl() {
  const base = getApiBaseUrl();
  if (base) {
    return base.replace(/^http/, "ws");
  }
  const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
  return `${protocol}//${window.location.host}`;
}
