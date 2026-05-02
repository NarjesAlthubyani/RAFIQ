import sys
import os
import asyncio
import time
backend_path = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, backend_path)

from services.trip_planner import generate_trip_plan

class TestTripCreationPerformance:
    
    def test_performance_comparison(self):

        # Performance comparison across different cities
        test_cases = [
            ("Riyadh", 3, ["history", "food"], 3000),
            ("Jeddah", 2, ["nature", "shopping"], 2000),
            ("AlUla", 6, ["history", "nature"], 10000),
        ]
        
        # Print table header for performance results
        print("-"*60)
        print("\nCity    Days    Time (s)")
        print("-"*60)
        
        for city, days, interests, budget in test_cases:
            start = time.time()
            # Generate trip plan
            result = asyncio.run(generate_trip_plan(city, days, interests, budget))
            # Calculate execution time
            duration = time.time() - start
            # Display result
            print(f"{city}    {days}    {duration:.2f}")

if __name__ == "__main__":
    test = TestTripCreationPerformance()
    test.test_performance_comparison()

    