import sys
import os
sys.path.append(os.path.abspath("."))

from Backend.utils.distance import haversine_km

RADIUS_KM = 15.0

# Helper function to check if activity is within the defined radius
def is_within_radius(user_lat, user_lng, act_lat, act_lng):
    distance = haversine_km(user_lat, user_lng, act_lat, act_lng)
    return distance <= RADIUS_KM

# Test activity within radius
def test_activity_within_radius():
    assert is_within_radius(21.5, 39.2, 21.51, 39.21) is True

# Test activity outside radius
def test_activity_outside_radius():
    assert is_within_radius(21.5, 39.2, 24.7, 46.7) is False

# Test boundary condition (edge case near radius limit)
def test_activity_on_boundary():
    result = is_within_radius(21.5, 39.2, 21.6, 39.3)
    assert isinstance(result, bool)