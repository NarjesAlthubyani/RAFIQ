
import sys
import os
from pathlib import Path
sys.path.append(os.path.abspath("."))
from fastapi.testclient import TestClient
from Backend.main import app
client = TestClient(app)
TEST_IMAGE_PATH = Path("Backend/tests/test_images/elephant_rock_test.jpg")
# Test valid landmark image upload
def test_landmark_valid_image_upload():
    assert TEST_IMAGE_PATH.exists(), "Test image file does not exist."
    with open(TEST_IMAGE_PATH, "rb") as image_file:
        response = client.post(
            "/api/landmarks/recognize",
            files={"image": ("elephant_rock_test.jpg", image_file, "image/jpeg")} )
    assert response.status_code == 200
    data = response.json()
    assert "recognized" in data
    assert isinstance(data["recognized"], bool)
    if data["recognized"] is True:
        assert "landmark_name" in data
        assert "description" in data
    else:
        assert data["error"] == "Unable to Recognize Landmark"
        assert "confidence" in data
# Test request without uploading an image
def test_landmark_missing_image():
    response = client.post("/api/landmarks/recognize")
    assert response.status_code == 422
# Test wrong HTTP method
def test_landmark_wrong_method():
    response = client.get("/api/landmarks/recognize")
    assert response.status_code == 405