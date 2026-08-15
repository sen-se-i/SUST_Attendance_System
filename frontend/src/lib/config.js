const RENDER_BACKEND_URL = "https://jarvis-att.onrender.com";

export function getApiBaseUrl() {
  const saved = localStorage.getItem("jarvisatt.api_url");
  if (saved) return saved.replace(/\/$/, "");

  if (import.meta.env.VITE_API_BASE_URL) {
    return import.meta.env.VITE_API_BASE_URL.replace(/\/$/, "");
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
