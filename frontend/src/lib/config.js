// In the browser (served by Spring, or the Vite dev server via proxy) this stays
// empty and every request is relative to the current origin. Inside the Capacitor
// native shell the app's own origin is not the backend, so a real backend URL must
// be baked in at build time via VITE_API_BASE_URL.
export const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || "").replace(/\/$/, "");

export function wsBaseUrl() {
  if (API_BASE_URL) {
    return API_BASE_URL.replace(/^http/, "ws");
  }
  const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
  return `${protocol}//${window.location.host}`;
}
