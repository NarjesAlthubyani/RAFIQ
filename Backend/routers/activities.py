from typing import Optional
from fastapi import APIRouter, Query
from Backend.services.activity_explorer import get_activities

router = APIRouter()

@router.get("")
async def activities(
    lat: float = Query(..., description="User latitude"),
    lng: float = Query(..., description="User longitude"),
    limit: int = Query(20, ge=1, le=100),
    available_minutes: Optional[int] = Query(
        None,
        ge=1,
        description="Optional: filter activities by available time (minutes). If omitted, returns nearby activities only."
    ),
):
    
  # Receive user location and optional filters, then forward to service layer
    return await get_activities(
        lat=lat,
        lng=lng,
        limit=limit,
        available_minutes=available_minutes,
    )