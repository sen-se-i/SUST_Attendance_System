const MIN_TARGET_ACCURACY_METERS = 3;

function getPosition(timeout = 6000) {
  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(resolve, reject, {
      enableHighAccuracy: true,
      maximumAge: 0,
      timeout,
    });
  });
}

export async function captureCalibratedLocation(radiusMeters = 20) {
  if (!navigator.geolocation) {
    throw new Error("Geolocation is not supported by this device.");
  }

  const targetAccuracyMeters = Math.max(MIN_TARGET_ACCURACY_METERS, Number(radiusMeters) || 20);
  let best = null;

  for (let attempt = 0; attempt < 6; attempt += 1) {
    const position = await getPosition();
    if (!best || position.coords.accuracy < best.coords.accuracy) {
      best = position;
    }
    if (position.coords.accuracy <= targetAccuracyMeters) {
      break;
    }
    await new Promise((resolve) => setTimeout(resolve, 700));
  }

  if (!best) {
    throw new Error("No GPS fix returned.");
  }

  const accuracyMeters = best.coords.accuracy;
  if (!Number.isFinite(accuracyMeters) || accuracyMeters <= 0) {
    throw new Error("GPS did not report usable accuracy. Please try again.");
  }
  if (accuracyMeters > targetAccuracyMeters) {
    throw new Error(
      `GPS accuracy is ${accuracyMeters.toFixed(1)}m, but this session needs ${targetAccuracyMeters.toFixed(1)}m or better. Stand still near a window and try again.`,
    );
  }

  return {
    latitude: best.coords.latitude,
    longitude: best.coords.longitude,
    accuracyMeters,
    capturedAt: new Date(best.timestamp || Date.now()).toISOString(),
  };
}
