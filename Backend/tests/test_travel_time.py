import pytest
from Backend.services.trip_planner import TripPlanner

class TestRealPlacesTravelTime:
    def setup_method(self):
        self.planner = TripPlanner()
    
    # Travel time between Kingdom Tower and Al Faisaliah Tower
    def test_riyadh_kingdom_tower_to_faisaliah_tower(self):
        
        kingdom_tower = {'name': 'Kingdom Tower', 'lat': 24.7136, 'lng': 46.6753}
        faisaliah_tower = {'name': 'Al Faisaliah Tower', 'lat': 24.6889, 'lng': 46.6851}
        travel_time = self.planner.calculate_distance_time(kingdom_tower, faisaliah_tower)
        
        # Approximately 5km apart → 15 or 20 minutes
        assert travel_time in [15, 20]
    
     # Travel time from King Fahd Fountain to Jeddah Corniche
    def test_jeddah_fountain_to_corniche(self):
        
        fountain = {'name': 'King Fahd Fountain', 'lat': 21.5433, 'lng': 39.1728}
        corniche = {'name': 'Jeddah Corniche', 'lat': 21.5447, 'lng': 39.1553}
        travel_time = self.planner.calculate_distance_time(fountain, corniche)
        
        # Approximately 2km apart → 10 minutes
        assert travel_time == 10

    # Travel time from Hegra to Elephant Rock 
    def test_alula_hegra_to_elephant_rock(self):
        
        hegra = {'name': 'Hegra', 'lat': 26.8112, 'lng': 37.9543}
        elephant_rock = {'name': 'Elephant Rock', 'lat': 26.6080, 'lng': 37.9236}
        travel_time = self.planner.calculate_distance_time(hegra, elephant_rock)
        
        # Approximately 22km apart → 30 minutes
        assert travel_time == 30
    
    # Travel time from Elephant Rock to AlUla Old Town
    def test_alula_elephant_rock_to_old_town(self):
        
        elephant_rock = {'name': 'Elephant Rock', 'lat': 26.6080, 'lng': 37.9236}
        old_town = {'name': 'AlUla Old Town', 'lat': 26.6089, 'lng': 37.9153}
        travel_time = self.planner.calculate_distance_time(elephant_rock, old_town)
        
        # Approximately 1km apart → 5 minutes
        assert travel_time == 5

        
    