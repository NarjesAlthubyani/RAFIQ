
import sys
import os

sys.path.append(os.path.abspath("."))

from Backend.utils.distance import haversine_km

# -----------------------
# Distance Tests
def test_same_location():
    result = haversine_km(21.5, 39.2, 21.5, 39.2)
    assert result == 0

def test_nearby_location():
    result = haversine_km(21.5, 39.2, 21.6, 39.3)
    assert result > 0 and result < 20

def test_far_location():
    result = haversine_km(21.5, 39.2, 24.7, 46.7)  # جدة → الرياض
    assert result > 500
