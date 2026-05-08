import pytest
from Backend.services.planning_services import RouteOptimizer
from types import SimpleNamespace

class TestRealRouteOptimizer:

    def setup_method(self):
        self.optimizer = RouteOptimizer()

    # Test route optimization for real Riyadh locations
    def test_route_optimizer_riyadh(self):

        places = [
            SimpleNamespace(name='Kingdom Tower', lat=24.7136, lng=46.6753),
            SimpleNamespace(name='Al Faisaliah', lat=24.6889, lng=46.6851),
            SimpleNamespace(name='Boulevard Riyadh', lat=24.7743, lng=46.7395),
            SimpleNamespace(name='KAFD', lat=24.7600, lng=46.6400),
        ]

        # Run the optimizer to generate a route
        optimized = self.optimizer.optimize(places)

        # Ensure the optimizer returns the same number of places
        assert len(optimized) == len(places)

        # Ensure the first place remains the starting point
        assert optimized[0].name == places[0].name

    # Test optimizer behavior for locations far apart in Saudi Arabia
    def test_route_optimizer_far_locations(self):

        places = [
            SimpleNamespace(name='Riyadh Tower', lat=24.7136, lng=46.6753),
            SimpleNamespace(name='Jeddah Fountain', lat=21.5433, lng=39.1728),
            SimpleNamespace(name='AlUla Hegra', lat=26.8112, lng=37.9543),
        ]

        # Optimize the route for distant cities
        optimized = self.optimizer.optimize(places)

        # Ensure all places are included
        assert len(optimized) == 3

        # Ensure the first place remains the starting point
        assert optimized[0].name == 'Riyadh Tower'

