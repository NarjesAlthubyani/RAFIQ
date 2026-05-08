from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from Backend.services.trip_planner_service import trip_planner_service

router = APIRouter(prefix="/api/trip-planner", tags=["trip-planner"])

class PlanRequest(BaseModel):
    city: str
    days: int
    interests: list[str]
    budget: float

@router.post("/plan")
async def plan_trip(req: PlanRequest):

    try:
        # Call the trip planner service
        plan = await trip_planner_service.create_trip_plan(
            city=req.city,
            days=req.days,
            interests=req.interests,
            budget=req.budget,
        )

        # Validate service output
        if not plan or "days" not in plan:
            raise ValueError("Trip planner returned invalid data")

        return plan
    
    # Validation or data issues
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    # Unexpected errors
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Trip planning failed: {e}")

