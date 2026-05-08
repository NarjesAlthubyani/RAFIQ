import pytest
from Backend.services.trip_planner_service import TripPlannerService

class TestFullTripCreationReal:

    # method to run TripPlannerService
    async def _run(self, city, days, interests, budget):
        planner = TripPlannerService()
        return await planner.create_trip_plan(
            city=city,
            days=days,
            interests=interests,
            budget=budget
        )

    # Test 1: Create a 3-day trip for Riyadh 
    @pytest.mark.asyncio
    async def test_create_riyadh_trip_3_days(self):
        city = "Riyadh"
        days = 3
        interests = ["history", "food", "shopping"]
        budget = 3000

        result = await self._run(city, days, interests, budget)

        # Structure checks
        assert result is not None
        assert "days" in result
        assert "total_cost" in result
        assert "summary" in result

        # Days count
        assert len(result["days"]) == days

        # Activities count
        total_activities = sum(len(day["activities"]) for day in result["days"])
        assert total_activities > 0

        # Cost
        assert result["total_cost"] > 0

        # Summary
        assert city in result["summary"]

    # Test 2: Create a 4-day trip for Jeddah
    @pytest.mark.asyncio
    async def test_create_jeddah_trip_4_days(self):
        result = await self._run("Jeddah", 4, ["nature", "entertainment"], 5000)

        assert result is not None
        assert len(result["days"]) == 4
        assert result["total_cost"] > 0


    # Test 3: Create a 2-day trip for AlUla
    @pytest.mark.asyncio
    async def test_create_alula_trip_2_days(self):
        result = await self._run("AlUla", 2, ["history", "nature"], 1500)

        assert result is not None
        assert len(result["days"]) == 2
        assert result["total_cost"] > 0
