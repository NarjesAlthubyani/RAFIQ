from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
from Backend.services.trip_planner import generate_trip_plan 

# Set up router with base path and tag for API docs
router = APIRouter(prefix="/api/trip-planner", tags=["Trip Planner"])

# Expected request body format from frontend
class TripRequest(BaseModel):
    city: str
    days: int
    interests: List[str]
    budget: float

# POST endpoint to generate a trip plan
@router.post("/plan")
async def plan_trip(request: TripRequest):
    try:
        # Pass validated request data to the trip planner service
        result = await generate_trip_plan(
            city=request.city,
            days=request.days,
            interests=request.interests,
            budget=request.budget
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))