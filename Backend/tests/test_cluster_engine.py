import pytest
from Backend.services.planning_services import ClusterEngine
from types import SimpleNamespace

class TestRealPlacesClustering:

    def setup_method(self):
        self.engine = ClusterEngine()

    # Test that nearby Riyadh landmarks are grouped into the same cluster
    def test_nearby_riyadh_places_cluster(self):
        
        places = [
            # Kingdom Tower and Faisaliah Tower are close to each other
            SimpleNamespace(name='Kingdom Centre Tower', lat=24.7136, lng=46.6753),
            SimpleNamespace(name='Al Faisaliah Tower', lat=24.6889, lng=46.6851),
            # KAFD is slightly farther but still within Riyadh
            SimpleNamespace(name='KAFD', lat=24.7600, lng=46.6400),
        ]

        # Run clustering on the provided real coordinates
        clusters = self.engine.cluster(places)

        assert any(len(c) >= 2 for c in clusters)

    # Test clustering behavior for real locations in Jeddah Corniche
    def test_jeddah_cluster(self):

        places = [
            SimpleNamespace(name='King Fahd Fountain', lat=21.5433, lng=39.1728),
            SimpleNamespace(name='Jeddah Corniche', lat=21.5447, lng=39.1553),
            SimpleNamespace(name='Floating Mosque', lat=21.6296, lng=39.1044),
            SimpleNamespace(name='Jeddah Waterfront', lat=21.6015, lng=39.1100),
        ]

        # Cluster Jeddah locations
        clusters = self.engine.cluster(places)

        assert any(len(c) >= 2 for c in clusters)

    def test_saudi_cities(self):
    
        places = [
            SimpleNamespace(name='Riyadh Tower', lat=24.7136, lng=46.6753),
            SimpleNamespace(name='Jeddah Fountain', lat=21.5433, lng=39.1728),
            SimpleNamespace(name='AlUla Hegra', lat=26.8112, lng=37.9543),
        ]

        # Cluster distant cities
        clusters = self.engine.cluster(places)

        assert len(clusters) >= 2

        
