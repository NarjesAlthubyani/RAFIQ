import sys
import os

sys.path.append(os.path.abspath("."))

from fastapi.testclient import TestClient
from Backend.main import app

client = TestClient(app)

# Test valid request with latitude and longitude
def test_nearby_activities_endpoint():
    response = client.get("/activities?lat=21.5&lng=39.2")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

# Test request without required parameters
def test_nearby_missing_params():
    response = client.get("/activities")
    assert response.status_code == 422

# Test request with invalid latitude and longitude values
def test_nearby_invalid_input():
    response = client.get("/activities?lat=abc&lng=xyz")
    assert response.status_code != 200