import { getApiBaseUrl } from "./config";

const TOKEN_KEY = "jarvisatt.token";

export class ApiError extends Error {}

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token) {
  if (token) localStorage.setItem(TOKEN_KEY, token);
  else localStorage.removeItem(TOKEN_KEY);
}

const REQUEST_TIMEOUT_MS = 90000;

export async function api(path, options = {}) {
  const headers = { ...(options.headers || {}) };
  if (!(options.body instanceof FormData)) headers["Content-Type"] = "application/json";
  const token = getToken();
  if (token && !path.startsWith("/api/auth/login") && !path.startsWith("/api/auth/register") && !path.startsWith("/api/auth/reset-password")) {
    headers.Authorization = `Bearer ${token}`;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  let response;
  try {
    const baseUrl = getApiBaseUrl();
    response = await fetch(`${baseUrl}${path}`, { ...options, headers, signal: controller.signal });
  } catch (error) {
    if (error.name === "AbortError") {
      throw new ApiError("The server took too long to respond. It may be waking up — please try again.");
    }
    throw new ApiError("Could not reach the server. Please ensure the backend is running at http://localhost:8080 and try again.");
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    let message = `Request failed (${response.status})`;
    try {
      const body = await response.json();
      message = body.message || message;
    } catch {

    }
    throw new ApiError(message);
  }
  if (response.status === 204) return null;
  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

