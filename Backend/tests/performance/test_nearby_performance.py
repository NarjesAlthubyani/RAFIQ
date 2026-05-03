import sys
import os
import time

sys.path.append(os.path.abspath("."))

from fastapi.testclient import TestClient
from Backend.main import app

client = TestClient(app)


def test_nearby_performance_comparison():
    # Test cases for different locations
    test_cases = [
        ("Jeddah", 21.5, 39.2),
        ("Riyadh", 24.7, 46.7),
        ("AlUla", 26.8, 37.9),
    ]

    print("\n----------------------------------------")
    print("City       Time (s)")
    print("----------------------------------------")

    for city, lat, lng in test_cases:
        start_time = time.time()

        response = client.get(f"/activities?lat={lat}&lng={lng}")

        end_time = time.time()
        duration = end_time - start_time

        print(f"{city:<10} {duration:.2f}")

        assert response.status_code == 200