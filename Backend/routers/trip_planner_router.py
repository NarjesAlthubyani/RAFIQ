from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
from Backend.services.trip_planner import generate_trip_plan 

router = APIRouter(prefix="/api/trip-planner", tags=["Trip Planner"])

class TripRequest(BaseModel):
    city: str
    days: int
    interests: List[str]
    budget: float

@router.post("/plan")
async def plan_trip(request: TripRequest):
    try:
        result = await generate_trip_plan(
            city=request.city,
            days=request.days,
            interests=request.interests,
            budget=request.budget
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))