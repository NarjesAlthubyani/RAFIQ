import os
from typing import Any, Dict, List
import httpx

SUPABASE_URL = os.getenv("SUPABASE_URL", "").strip()
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "").strip()
DEFAULT_TABLE = "NearBy_activity"

def _assert_env() -> None:
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise RuntimeError(
            "Missing SUPABASE_URL or SUPABASE_ANON_KEY. Put them in .env then restart uvicorn."
        )

def _headers() -> Dict[str, str]:
    # Prepare headers for Supabase request
    return {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Accept": "application/json",
    }

# Normalize database record
def normalize_record(row: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "id": f"db:{row['id']}",
        "source": "rafiq_db",
        "title": row["name"],
        "category": row["category"],
        "imageUrl": row.get("image_url"),
        "lat": float(row["lat"]),
        "lng": float(row["lng"]),
        "durationMinutes": int(row["duration_minutes"]) if row["duration_minutes"] is not None else None,
        "detailsUrl": row["location_link"],
        "ticketBooking": row.get("ticket_booking"),
        "ticketLink": row.get("ticket_link"),
    }

async def fetch_db_activities(
    *,
    limit: int = 200,
    table: str = DEFAULT_TABLE,
) -> List[Dict[str, Any]]:
    _assert_env()

    base = SUPABASE_URL.rstrip("/")
    url = f"{base}/rest/v1/{table}"

    params: Dict[str, str] = {
        "select": "id,name,location_link,category,lat,lng,duration_minutes,image_url,ticket_booking,ticket_link",
        "limit": str(max(1, min(limit, 1000))),
        "order": "id.asc",
    }

     # Send request to Supabase
    async with httpx.AsyncClient(timeout=20.0) as client:
        resp = await client.get(url, headers=_headers(), params=params)

    if resp.status_code >= 400:
        raise RuntimeError(f"Supabase REST error {resp.status_code}: {resp.text}")

    rows = resp.json()
    # Convert raw database rows into normalized format
    return [normalize_record(r) for r in rows]
