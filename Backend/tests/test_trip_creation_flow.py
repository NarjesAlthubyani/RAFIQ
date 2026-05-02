import sys
import os
from unittest import result
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import pytest
import asyncio
from datetime import datetime
from Backend.services.trip_planner import generate_trip_plan, TripPlanner

class TestFullTripCreation:
    @pytest.mark.asyncio
    # Test: Create 4-day trip to Riyadh
    async def test_create_riyadh_trip_3_days(self):

        city = "Riyadh"
        days = 3
        interests = ["history", "food", "shopping"]
        budget = 3000

        result = await generate_trip_plan(city, days, interests, budget)

        # Check main response structure
        assert result is not None, "Result should not be None"
        assert 'days' in result, "Missing 'days' key"
        assert 'total_cost' in result, "Missing 'total_cost' key"
        assert 'summary' in result, "Missing 'summary' key"

        days_list = result['days']
        assert len(days_list) == days, f"Expected {days} days, got {len(days_list)}"

        # Calculate total activities
        total_activities = 0

        for i, day in enumerate(days_list, 1):
            assert 'day' in day, f"Day {i} missing 'day' key"
            assert 'activities' in day, f"Day {i} missing 'activities' key"
            assert 'daily_cost' in day, f"Day {i} missing 'daily_cost' key"

            total_activities += len(day['activities'])

        # Ensure trip has at least one activity
        assert total_activities > 0, "Trip should contain at least one activity"

        total_cost = result['total_cost']
        assert total_cost > 0, "Total cost should be positive"
        assert total_cost <= budget * 1.2, f"Cost exceeds budget limit"

        summary = result['summary']
        assert summary, "Summary should not be empty"
        assert city in summary, f"Summary should mention {city}"

    @pytest.mark.asyncio
    # Test: Create 4-day trip to Jeddah
    async def test_create_jeddah_trip_4_days(self):

        result = await generate_trip_plan("Jeddah",4,["nature", "entertainment"],5000)

        assert result is not None
        assert len(result['days']) == 4
        assert result['total_cost'] > 0

    @pytest.mark.asyncio
    # Test: Create 2-day trip to AlUla
    async def test_create_alula_trip_2_days(self):

        result = await generate_trip_plan("AlUla",2,["history", "nature"],1000)

        assert result is not None
        assert len(result['days']) == 2
        assert result['total_cost'] > 0

    @pytest.mark.asyncio
    # Test: Create trip with minimum budget
    async def test_create_trip_minimum_budget(self):
    
        city = "Riyadh"
        days = 1
        interests = ["food"]
        budget = 500  
    
        result = await generate_trip_plan(city, days, interests, budget)
    
        assert result is not None
        assert len(result['days']) == days
        assert result['total_cost'] > 0

        
