import { API_BASE_URL } from "./config";

const TOKEN_KEY = "jarvisatt.token";

export class ApiError extends Error {}

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token) {
  if (token) localStorage.setItem(TOKEN_KEY, token);
  else localStorage.removeItem(TOKEN_KEY);
}

// The backend runs on a free host that sleeps when idle and can take up to a
// minute to wake, so allow a generous timeout before giving up.
const REQUEST_TIMEOUT_MS = 90000;

export async function api(path, options = {}) {
  const headers = { ...(options.headers || {}) };
  if (!(options.body instanceof FormData)) headers["Content-Type"] = "application/json";
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  let response;
  try {
    response = await fetch(`${API_BASE_URL}${path}`, { ...options, headers, signal: controller.signal });
  } catch (error) {
    if (error.name === "AbortError") {
      throw new ApiError("The server took too long to respond. It may be waking up — please try again.");
    }
    throw new ApiError("Could not reach the server. Check your internet connection and try again.");
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    let message = `Request failed (${response.status})`;
    try {
      const body = await response.json();
      message = body.message || message;
    } catch {
      // response had no JSON body, keep default message
    }
    throw new ApiError(message);
  }
  if (response.status === 204) return null;
  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

export async function fetchQrBlob(sessionId) {
  const token = getToken();
  const response = await fetch(`${API_BASE_URL}/api/sessions/${sessionId}/qr.png?bust=${Date.now()}`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });
  if (!response.ok) throw new ApiError(`QR fetch failed (${response.status})`);
  return response.blob();
}
