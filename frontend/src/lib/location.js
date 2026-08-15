// Maximum GPS accuracy accepted by the backend (must match AttendanceService.requireValidAccuracy).
const MAX_ACCEPTED_ACCURACY_METERS = 40;
// Absolute minimum accuracy we ever request (for very small geofences).
const MIN_TARGET_ACCURACY_METERS = 3;

function getPosition(timeout = 8000) {
  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(resolve, reject, {
      enableHighAccuracy: true,
      maximumAge: 0,
      timeout,
    });
  });
}

/**
 * Captures the best GPS fix achievable within the given session radius.
 *
 * Strategy:
 *  - Ideal target:  accuracy = radius / 2  — retries until this is achieved or
 *                   8 attempts are exhausted, keeping the best reading each time.
 *  - Hard reject:   accuracy > min(40m, radius × 2) — GPS is so bad the reported
 *                   center can't be trusted; mirrors the backend quality gate.
 *  - Otherwise:     submit to backend. The backend's "center-inside" check
 *                   (distance <= radius) makes the final call.
 *
 * This allows students at the back of the room (near the boundary) to pass as
 * long as their GPS center is inside the zone, regardless of accuracy margin.
 *
 * Retries up to 8 times with 1 second between attempts so the device
 * has plenty of time to converge to a tighter fix.
 */
export async function captureCalibratedLocation(radiusMeters = 20) {
  if (!navigator.geolocation) {
    throw new Error("Geolocation is not supported by this device.");
  }

  const radius = Math.max(5, Number(radiusMeters) || 20);

  // Ideal target: half the radius — gives room for the backend's center-inside check.
  const idealAccuracyMeters = Math.min(
    MAX_ACCEPTED_ACCURACY_METERS,
    Math.max(MIN_TARGET_ACCURACY_METERS, radius / 2),
  );

  // Hard limit: mirrors backend quality gate — min(40m, radius * 2).
  // GPS worse than this is so unreliable the center can't be trusted at all.
  const hardLimitMeters = Math.min(MAX_ACCEPTED_ACCURACY_METERS, radius * 2);

  let best = null;

  for (let attempt = 0; attempt < 8; attempt += 1) {
    let position;
    try {
      position = await getPosition();
    } catch {
      if (attempt === 7) throw new Error("GPS signal lost. Please enable location permission and try again.");
      await new Promise((resolve) => setTimeout(resolve, 1000));
      continue;
    }

    if (!best || position.coords.accuracy < best.coords.accuracy) {
      best = position;
    }

    // Early exit if we hit the ideal target
    if (best.coords.accuracy <= idealAccuracyMeters) {
      break;
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  if (!best) {
    throw new Error("No GPS fix returned.");
  }

  const accuracyMeters = best.coords.accuracy;
  if (!Number.isFinite(accuracyMeters) || accuracyMeters <= 0) {
    throw new Error("GPS did not report usable accuracy. Please try again.");
  }

  // Hard reject: accuracy > min(40m, radius*2) — backend quality gate.
  // If GPS is this bad the center position can't be trusted at all.
  if (accuracyMeters > hardLimitMeters) {
    throw new Error(
      `GPS accuracy is ${accuracyMeters.toFixed(1)}m — too weak for this ${radius}m session. ` +
      `Enable High Accuracy mode (Wi-Fi + Mobile Data ON) and stand still, then retry.`,
    );
  }

  // Accuracy passed the quality gate — submit and let the backend's center-inside
  // check (distance <= radius) make the final call.
  return {
    latitude: best.coords.latitude,
    longitude: best.coords.longitude,
    accuracyMeters,
    capturedAt: new Date(best.timestamp || Date.now()).toISOString(),
  };
}
