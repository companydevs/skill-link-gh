/**
 * Cloud Function: getDistanceMatrix
 * Calls Google Distance Matrix API to get real road distances + travel times.
 * API key is stored server-side — never exposed to the client.
 *
 * Enable: Google Distance Matrix API in Google Cloud Console
 * Set env: firebase functions:config:set google.maps_key="YOUR_KEY"
 * Or use Secret Manager for production.
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import axios from "axios";

if (!admin.apps.length) admin.initializeApp();

// Simple in-memory cache: key -> {data, expiresAt}
const cache = new Map<string, { data: DistanceResult[]; expiresAt: number }>();
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

interface DistanceResult {
  artisanId: string;
  distanceKm: number;
  durationMinutes: number;
}

export const getDistanceMatrix = onCall(async (request) => {
  const { originLat, originLng, destinations } = request.data as {
    originLat: number;
    originLng: number;
    destinations: Array<{ id: string; lat: number; lng: number }>;
  };

  if (!originLat || !originLng || !destinations?.length) {
    throw new HttpsError("invalid-argument", "Missing required parameters");
  }

  // Limit to 25 destinations per call (API limit is 25 per request)
  const batch = destinations.slice(0, 25);

  // Cache key based on origin + destination IDs
  const cacheKey = `${originLat.toFixed(4)},${originLng.toFixed(4)}|${batch.map((d) => d.id).join(",")}`;
  const cached = cache.get(cacheKey);
  if (cached && Date.now() < cached.expiresAt) {
    return { results: cached.data };
  }

  const apiKey = process.env.GOOGLE_MAPS_KEY;
  if (!apiKey) {
    throw new HttpsError("failed-precondition", "Maps API key not configured");
  }

  const origin = `${originLat},${originLng}`;
  const destinationsParam = batch.map((d) => `${d.lat},${d.lng}`).join("|");

  try {
    const response = await axios.get(
      "https://maps.googleapis.com/maps/api/distancematrix/json",
      {
        params: {
          origins: origin,
          destinations: destinationsParam,
          mode: "driving",
          units: "metric",
          key: apiKey,
        },
        timeout: 8000,
      }
    );

    const data = response.data;
    if (data.status !== "OK") {
      throw new HttpsError("internal", `Distance Matrix API error: ${data.status}`);
    }

    const elements = data.rows[0]?.elements ?? [];
    const results: DistanceResult[] = batch.map((dest, i) => {
      const el = elements[i];
      if (el?.status === "OK") {
        return {
          artisanId: dest.id,
          distanceKm: parseFloat((el.distance.value / 1000).toFixed(1)),
          durationMinutes: Math.ceil(el.duration.value / 60),
        };
      }
      // Fallback: straight-line estimate
      const dlat = dest.lat - originLat;
      const dlng = dest.lng - originLng;
      const straightKm = Math.sqrt(dlat * dlat + dlng * dlng) * 111;
      return {
        artisanId: dest.id,
        distanceKm: parseFloat(straightKm.toFixed(1)),
        durationMinutes: Math.ceil(straightKm * 3),
      };
    });

    // Cache the result
    cache.set(cacheKey, { data: results, expiresAt: Date.now() + CACHE_TTL_MS });

    return { results };
  } catch (e: any) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("internal", `Failed to fetch distances: ${e.message}`);
  }
});
