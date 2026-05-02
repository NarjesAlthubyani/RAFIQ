import pytest
from Backend.services.trip_planner import TripPlanner

class TestInterestBasedSelection:
    
    def setup_method(self):
       
        self.planner = TripPlanner()
    
    def test_exact_match_gives_highest_score(self):
        # Test if exact matching interests give higher score compared to unrelated interests
        
        place = {
            'name': 'National Museum',
            'category': 'history',
            'all_tags': ['history', 'culture', 'art']
        }
        
        # interests that match the place tags
        matching_interests = ['history', 'culture']
        matching_score = self.planner.score_place(place, matching_interests)
        
        # interests that do not match the place
        non_matching_interests = ['shopping', 'food']
        non_matching_score = self.planner.score_place(place, non_matching_interests)
        
        # score should be higher when interests match
        assert matching_score > non_matching_score
        assert matching_score >= 5  
    
    def test_partial_match_gives_medium_score(self):
        # Test partial matching between interests and place tags
        
        place = {
            'name': 'Historical Site',
            'category': 'historical_site',
            'all_tags': ['history', 'old']
        }
        
        interests = ['history']
        
        score = self.planner.score_place(place, interests)
        
        # should still give some score even if partial match
        assert score >= 2
    
    def test_no_match_gives_zero_score(self):
        # Test case where no interests match place tags
        
        place = {
            'name': 'Restaurant',
            'category': 'restaurant',
            'all_tags': ['food', 'dinner']
        }
        
        interests = ['history', 'nature']
        
        score = self.planner.score_place(place, interests)
        
        # no match means score should be zero
        assert score == 0
    
    def test_selected_attractions_match_user_interests(self):
        # Test if final selected attractions reflect user interests after scoring
        
        all_attractions = [
            {'name': 'Museum', 'category': 'history', 'all_tags': ['history']},
            {'name': 'Tower', 'category': 'shopping', 'all_tags': ['shopping']},
            {'name': 'Park', 'category': 'nature', 'all_tags': ['nature']},
            {'name': 'Restaurant', 'category': 'food', 'all_tags': ['food']},
        ]
        
        interests = ['history', 'nature']
        
        # assign score to each place based on interests
        for place in all_attractions:
            place['score'] = self.planner.score_place(place, interests)
        
        # sort places by score (highest first)
        all_attractions.sort(key=lambda x: x['score'], reverse=True)
        
        # top results should match user interests
        assert all_attractions[0]['category'] in ['history', 'nature']
        assert all_attractions[1]['category'] in ['history', 'nature']


        