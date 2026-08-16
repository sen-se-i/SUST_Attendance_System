
const MAX_ACCEPTED_ACCURACY_METERS = 40;

const MIN_TARGET_ACCURACY_METERS = 3;

function getPosition(timeout = 5000, maximumAge = 2000) {
  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(resolve, reject, {
      enableHighAccuracy: true,
      maximumAge,
      timeout,
    });
  });
}

export async function captureCalibratedLocation(radiusMeters = 20) {
  if (!navigator.geolocation) {
    throw new Error("Geolocation is not supported by this device.");
  }

  const radius = Math.max(5, Number(radiusMeters) || 20);

  const idealAccuracyMeters = Math.min(
    MAX_ACCEPTED_ACCURACY_METERS,
    Math.max(MIN_TARGET_ACCURACY_METERS, Math.min(15, radius / 2)),
  );

  const hardLimitMeters = Math.min(MAX_ACCEPTED_ACCURACY_METERS, radius * 2);

  let best = null;

  for (let attempt = 0; attempt < 5; attempt += 1) {
    let position;
    try {
      position = await getPosition(4000, attempt === 0 ? 2000 : 0);
    } catch {
      if (attempt === 4 && !best) {
        throw new Error("GPS signal lost. Please ensure location permission is enabled and try again.");
      }
      await new Promise((resolve) => setTimeout(resolve, 200));
      continue;
    }

    if (!best || position.coords.accuracy < best.coords.accuracy) {
      best = position;
    }

    if (best.coords.accuracy <= idealAccuracyMeters) {
      break;
    }

    if (attempt >= 2 && best.coords.accuracy <= Math.min(25, radius)) {
      break;
    }

    await new Promise((resolve) => setTimeout(resolve, 200));
  }

  if (!best) {
    throw new Error("No GPS fix returned. Please ensure location is enabled.");
  }

  const accuracyMeters = best.coords.accuracy;
  if (!Number.isFinite(accuracyMeters) || accuracyMeters <= 0) {
    throw new Error("GPS did not report usable accuracy. Please try again.");
  }

  if (accuracyMeters > hardLimitMeters) {
    throw new Error(
      `GPS accuracy is ±${accuracyMeters.toFixed(1)}m — too weak for this ${radius}m session. ` +
      `Enable High Accuracy GPS mode and stand still, then retry.`,
    );
  }

  return {
    latitude: best.coords.latitude,
    longitude: best.coords.longitude,
    accuracyMeters,
    capturedAt: new Date().toISOString(),
  };
}

