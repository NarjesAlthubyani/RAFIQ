import sys
import os
import time
from pathlib import Path

sys.path.append(os.path.abspath("."))

from fastapi.testclient import TestClient
from Backend.main import app

client = TestClient(app)

TEST_IMAGE_PATH = Path("Backend/tests/test_images/elephant_rock_test.jpg")

def test_landmark_performance_average():
    assert TEST_IMAGE_PATH.exists(), "Test image file does not exist."

    runs = 5
    total_time = 0

    print("\n-----------------------------------------")
    print("Image              Average Response Time (s)")
    print("-----------------------------------------")

    for _ in range(runs):
        start_time = time.time()

        with open(TEST_IMAGE_PATH, "rb") as image_file:
            response = client.post(
                "/api/landmarks/recognize",
                files={
                    "image": (
                        TEST_IMAGE_PATH.name,
                        image_file,
                        "image/jpeg",
                    )
                },
            )

        end_time = time.time()
        duration = end_time - start_time
        total_time += duration

        assert response.status_code == 200

    average_time = total_time / runs

    print(f"{'Elephant Rock':<18} {average_time:.2f}")
    print("-----------------------------------------")
    print(f"Overall Average Response Time: {average_time:.2f} seconds")
    print("-----------------------------------------")

    assert average_time < 10