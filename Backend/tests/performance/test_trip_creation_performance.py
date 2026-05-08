import pytest
import time
from Backend.services.trip_planner_service import TripPlannerService

# Global list to store performance results for all test cases
results = []

# print a summary table after all tests finish
@pytest.fixture(scope="session", autouse=True)
def print_table(request):

    def finalize():
        print("\n-------------------------------------")
        print("City      Days      Time (s)")
        print("-------------------------------------")

        # Loop through collected results and print them in formatted table
        for city, days, duration in results:
            print(f"{city:<10} {days:<5}    {duration:>6.2f}")

        print("-------------------------------------\n")

    request.addfinalizer(finalize)

# Performance Test 
class TestTripCreationPerformance:
    async def _run_with_timing(self, city, days, interests, budget):

        # Create a new instance of TripPlannerService
        planner = TripPlannerService()

        # Record start time
        start = time.time()

        # Call the main function to generate trip plan
        result = await planner.create_trip_plan(
            city=city,
            days=days,
            interests=interests,
            budget=budget
        )

        # Record end time
        end = time.time()

        # Calculate total execution time
        duration = end - start

        # Print performance result for this specific test case
        print(f"\nPerformance ({city}, {days} days): {duration:.2f} seconds")

        # Return both result and execution time
        return result, duration


    # Test 1: performance for Riyadh trip planning
    @pytest.mark.asyncio
    async def test_performance_riyadh(self):

        city = "Riyadh"
        days = 3

        # Run test and measure performance
        result, duration = await self._run_with_timing(
            city,
            days,
            ["history", "food", "shopping"],
            3000
        )

        # Store result for final summary table
        results.append((city, days, duration))

        # Basic assertion to ensure a result is returned
        assert result is not None

    # Test 2: performance for Jeddah trip planning
    @pytest.mark.asyncio
    async def test_performance_jeddah(self):

        city = "Jeddah"
        days = 2

        # Run test and measure performance
        result, duration = await self._run_with_timing(
            city,
            days,
            ["nature", "entertainment"],
            5000
        )

        # Store result for final summary table
        results.append((city, days, duration))

        # Ensure result is valid
        assert result is not None

    # Test 3:performance for AlUla trip planning
    @pytest.mark.asyncio
    async def test_performance_alula(self):

        city = "AlUla"
        days = 6

        # Run test and measure performance
        result, duration = await self._run_with_timing(
            city,
            days,
            ["history", "nature"],
            7000
        )

        # Store result for final summary table
        results.append((city, days, duration))

        # Ensure result is valid
        assert result is not None

