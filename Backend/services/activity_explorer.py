from typing import Any, Dict, List, Optional

from Backend.utils.distance import haversine_km
from Backend.adapters.db_adapter import fetch_db_activities


RADIUS_KM = 15.0 # km radius for nearby activities

# Helpers
def bucket_from_minutes(minutes: Optional[int]) -> Optional[str]:
    if minutes is None:
        return None
    if minutes < 60:
        return "<1h"
    if minutes <= 120:
        return "1-2h"
    if minutes <= 180:
        return "2-3h"
    return "3h+"


async def get_activities(
    lat: float,
    lng: float,
    limit: int = 100,
    available_minutes: Optional[int] = None,
) -> List[Dict[str, Any]]:
    source_items = await fetch_db_activities(limit=500)
    results: List[Dict[str, Any]] = []

    for item in source_items:
        item_lat = float(item["lat"])
        item_lng = float(item["lng"])

        dist = haversine_km(lat, lng, item_lat, item_lng)

        # Distance filter
        if dist > RADIUS_KM:
            continue

        # Time filter (if user provided it)
        if available_minutes is not None:
            dur = item.get("durationMinutes")
            if dur is None:
                continue

            dur = int(dur)

            if available_minutes == 60:
                if not (dur < 60):
                    continue
            elif available_minutes == 120:
                if not (60 <= dur <= 120):
                    continue
            elif available_minutes == 180:
                if not (120 < dur <= 180):
                    continue
            elif available_minutes >= 9999:
                if not (dur > 180):
                    continue
            else:
                if dur > int(available_minutes):
                    continue

        # enrich output
        it = dict(item)
        it["distanceKm"] = round(dist, 3)
        if it.get("durationBucket") is None:
            it["durationBucket"] = bucket_from_minutes(it.get("durationMinutes"))

        results.append(it)

    results.sort(key=lambda x: x["distanceKm"])
    return results[:limit]