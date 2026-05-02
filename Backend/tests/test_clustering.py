import pytest
from Backend.services.trip_planner import TripPlanner

class TestRealPlacesClustering:

    def setup_method(self):
        # Create a fresh instance for each test to ensure test isolation
        self.planner = TripPlanner()

    def test_nearby_riyadh_places_cluster(self):
        # Check that nearby locations in Riyadh are grouped into the same cluster

        places = [
            {'name': 'Kingdom Centre Tower', 'lat': 24.7136, 'lng': 46.6753},
            {'name': 'Al Faisaliah Tower', 'lat': 24.6889, 'lng': 46.6851},
            {'name': 'KAFD', 'lat': 24.7600, 'lng': 46.6400},
        ]

        clusters = self.planner.cluster_by_location(places)

        # Verify that at least one cluster contains multiple nearby places
        assert any(len(c) >= 2 for c in clusters)

    def test_jeddah_corniche_cluster(self):
        # Check clustering behavior for locations in the Jeddah Corniche area

        places = [
            {'name': 'King Fahd Fountain', 'lat': 21.5433, 'lng': 39.1728},
            {'name': 'Jeddah Corniche', 'lat': 21.5447, 'lng': 39.1553},
            {'name': 'Floating Mosque', 'lat': 21.6296, 'lng': 39.1044},
            {'name': 'Jeddah Waterfront', 'lat': 21.6015, 'lng': 39.1100},
        ]

        clusters = self.planner.cluster_by_location(places)

        # Ensure clustering groups nearby attractions together
        assert len(clusters) >= 1
        assert any(len(c) >= 2 for c in clusters)

    def test_saudi_cities_do_not_merge(self):
        # Ensure that geographically distant cities are not grouped together

        places = [
            {'name': 'Riyadh Tower', 'lat': 24.7136, 'lng': 46.6753},
            {'name': 'Jeddah Fountain', 'lat': 21.5433, 'lng': 39.1728},
            {'name': 'AlUla Hegra', 'lat': 26.8112, 'lng': 37.9543},
        ]

        clusters = self.planner.cluster_by_location(places)

        # Confirm that distant locations are separated into multiple clusters
        assert len(clusters) >= 2


        
