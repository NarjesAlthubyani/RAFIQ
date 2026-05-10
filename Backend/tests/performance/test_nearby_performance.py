import sys
import os
import time

sys.path.append(os.path.abspath("."))

from fastapi.testclient import TestClient
from Backend.main import app

client = TestClient(app)


def test_nearby_performance_average():
    test_cases = [
        ("Jeddah", 21.5, 39.2),
        ("Riyadh", 24.7, 46.7),
        ("AlUla", 26.8, 37.9),
    ]

    runs = 5
    all_durations = []

    print("\n-----------------------------------------")
    print("City        Average Response Time (s)")
    print("-----------------------------------------")

    for city, lat, lng in test_cases:
        total_time = 0

        for _ in range(runs):
            start_time = time.time()

            response = client.get(f"/activities?lat={lat}&lng={lng}")

            end_time = time.time()
            duration = end_time - start_time
            total_time += duration

            assert response.status_code == 200

        average_time = total_time / runs
        all_durations.append(average_time)

        print(f"{city:<10} {average_time:.2f}")

    overall_average = sum(all_durations) / len(all_durations)

    print("-----------------------------------------")
    print(f"Overall Average Response Time: {overall_average:.2f} seconds")
    print("-----------------------------------------")

    assert overall_average < 2