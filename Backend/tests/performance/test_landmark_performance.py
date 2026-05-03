import sys
import os
import time
from pathlib import Path

sys.path.append(os.path.abspath("."))

from fastapi.testclient import TestClient
from Backend.main import app

client = TestClient(app)

test_cases = [
    ("Elephant Rock", Path("Backend/tests/test_images/elephant_rock_test.jpg")),
]

def test_landmark_performance_comparison():
    print("\n----------------------------------------")
    print("Image              Time (s)")
    print("----------------------------------------")

    for image_name, image_path in test_cases:
        assert image_path.exists(), f"{image_name} test image does not exist."

        start_time = time.time()

        with open(image_path, "rb") as image_file:
            response = client.post(
                "/api/landmarks/recognize",
                files={"image": (image_path.name, image_file, "image/jpeg")}
            )

        duration = time.time() - start_time

        print(f"{image_name:<18} {duration:.2f}")

        assert response.status_code == 200