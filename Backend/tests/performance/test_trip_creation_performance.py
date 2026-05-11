import pytest
import time
from Backend.services.trip_planner_service import TripPlannerService

# Global list to store execution times for all 8 performance cases
all_durations = []

def convert_budget_range(budget_range):
    mapping = {
        "500-1000": 750,
        "1000-2000": 1500,
        "2000-5000": 3500,
        "5000-10000": 7500,
        "10000+": 12000
    }
    return mapping[budget_range]

# print the final average 
@pytest.fixture(scope="session", autouse=True)
def print_summary(request):

    def finalize():
        # Calculate the average execution time across all 8 cases
        avg = sum(d for _, _, d in all_durations) / len(all_durations)

        print("------------------------------------------------")
        print(f"Average Time Across 8 Cases: {avg:.2f} seconds")
        print("------------------------------------------------\n")

    request.addfinalizer(finalize)

class TestTripCreationPerformance:

    async def _run_case(self, city, days, interests, budget_range):
        planner = TripPlannerService()

        # Convert UI budget range → numeric backend value
        budget_value = convert_budget_range(budget_range)

        # Start timing
        start = time.time()

        # Execute the trip creation process
        result = await planner.create_trip_plan(
            city=city,
            days=days,
            interests=interests,
            budget=budget_value
        )

        # End timing
        end = time.time()
        duration = end - start

        # Ensure the trip plan was generated successfully
        assert result is not None
        return duration

    @pytest.mark.asyncio
    async def test_10_cases(self):

        # 8 different trip creation 
        cases = [
            ("Riyadh", 3, ["history", "food"], "500-1000"),
            ("Jeddah", 2, ["nature", "entertainment"], "1000-2000"),
            ("AlUla", 6, ["history", "nature"], "2000-5000"),
            ("Jeddah", 4, ["shopping", "food"], "5000-10000"),
            ("AlUla", 3, ["nature"], "10000+"),
            ("Jeddah", 2, ["entertainment", "adventure"], "500-1000"),
            ("Jeddah", 3, ["shopping", "culture"], "1000-2000"),
            ("Riyadh", 1, ["culture"], "2000-5000"),
        ]

        # Run all 8 cases and store their durations
        for city, days, interests, budget_range in cases:
            duration = await self._run_case(city, days, interests, budget_range)
            all_durations.append((city, days, duration))
            
