import os
import json
import math
import random
from supabase import create_client
from dotenv import load_dotenv
from typing import List, Dict, Any
from services.ai_adapter import AIAdapter
from datetime import datetime, timedelta

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


class TripPlanner:
    
    def __init__(self):
        self.ai_adapter = AIAdapter()
        self.day_start_hour = 9      
        self.day_end_hour = 21      
        self.lunch_time = 13        
        self.dinner_time = 19       
    
    def get_places_from_db(self, city: str) -> List[Dict]:
        response = supabase.table("saudi_places").select("*").eq("city", city).execute()
        
        for place in response.data:
            if place.get('duration_minutes') is None:
                place['duration_minutes'] = 120  
            if place.get('duration_minutes') == 0:
                place['duration_minutes'] = 90
        
        return response.data
    
    def get_place_duration(self, place: Dict) -> int:
        duration = place.get('duration_minutes', 120)
        if duration is None or duration <= 0:
            return 120
        return int(duration)
    
    def haversine_distance(self, lat1, lon1, lat2, lon2):
        R = 6371
        lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
        return R * 2 * math.asin(math.sqrt(a))
    
    def calculate_travel_time(self, lat1, lon1, lat2, lon2) -> int:
        if lat1 == 0 or lon1 == 0 or lat2 == 0 or lon2 == 0:
            return 30  
        
        distance = self.haversine_distance(lat1, lon1, lat2, lon2)
        
        if distance <= 1:
            return 5
        elif distance <= 3:
            return 10
        elif distance <= 5:
            return 15
        elif distance <= 10:
            return 20
        elif distance <= 15:
            return 25
        elif distance <= 20:
            return 35
        else:
            return 45
    
    def score_place(self, place: Dict, interests: List[str]) -> float:
        tags = place.get("logic_tags", [])
        category = place.get("category", "").lower()
        name = place.get("name", "").lower()
        
        score = 0
        for interest in interests:
            i = interest.lower()
            if i in tags:
                score += 3
            elif i in category:
                score += 2
            elif i in name:
                score += 1
        
        price = place.get("price_level", 2)
        score -= price * 0.3
        score += random.uniform(0, 0.3)
        return score
    
    def get_place_type(self, place: Dict) -> str:
        tags = place.get("logic_tags", [])
        if "shopping" in tags:
            return "shopping"
        if "culture" in tags:
            return "culture"
        if "coffee" in tags:
            return "coffee"
        if "activity" in tags:
            return "activity"
        return "other"
    
    def is_heavy(self, place: Dict) -> bool:
        tags = place.get("logic_tags", [])
        return "activity" in tags and "outdoor" in tags
    
    def cluster_by_location(self, places: List[Dict]) -> List[List[Dict]]:
        clusters = []
        used = [False] * len(places)
        
        for i in range(len(places)):
            if used[i]:
                continue
            
            cluster = [places[i]]
            used[i] = True
            
            for j in range(i + 1, len(places)):
                if used[j]:
                    continue
                
                lat1 = places[i].get('lat', 0)
                lng1 = places[i].get('lng', 0)
                lat2 = places[j].get('lat', 0)
                lng2 = places[j].get('lng', 0)
                
                if lat1 and lng1 and lat2 and lng2:
                    dist = self.haversine_distance(lat1, lng1, lat2, lng2)
                    if dist <= 3:
                        cluster.append(places[j])
                        used[j] = True
            
            clusters.append(cluster)
        
        return clusters
    
    def pick_unique(self, place_list: List[Dict], used_ids: set) -> Dict:
        for p in place_list:
            if p['id'] not in used_ids:
                used_ids.add(p['id'])
                return p
        return None
    
    def calculate_available_time(self, day: int, breakfast_exists: bool, lunch_exists: bool, dinner_exists: bool,
                                  breakfast_duration: int = 0, lunch_duration: int = 0, dinner_duration: int = 0) -> int:
        total_minutes = (self.day_end_hour - self.day_start_hour) * 60
        
        if breakfast_exists and breakfast_duration > 0:
            total_minutes -= breakfast_duration
        if lunch_exists and lunch_duration > 0:
            total_minutes -= lunch_duration
        if dinner_exists and dinner_duration > 0:
            total_minutes -= dinner_duration
        
        return max(120, total_minutes)
    
    def calculate_max_activities(self, attractions: List[Dict], available_minutes: int) -> int:
        if not attractions:
            return 0
        
        sorted_attractions = sorted(attractions, key=lambda x: self.get_place_duration(x))
        
        total_time = 0
        count = 0
        travel_time = 30
        
        for attr in sorted_attractions:
            duration = self.get_place_duration(attr)
            if total_time + duration + travel_time <= available_minutes:
                total_time += duration + travel_time
                count += 1
            else:
                break
        
        return max(1, min(count, 3))
    
    def create_daily_schedule(self, day: int, attractions: List[Dict], breakfast: Dict, lunch: Dict, dinner: Dict) -> Dict:
        activities = []
        current_time = self.day_start_hour
        
        def add(place, type_name):
            nonlocal current_time
            hours = int(current_time)
            minutes = int((current_time % 1) * 60)
            
            duration = self.get_place_duration(place)
            
            activities.append({
                "time": f"{hours:02d}:{minutes:02d}",
                "name": place.get('name'),
                "type": type_name,
                "duration": duration,
                "cost": place.get('price_level', 2) * 50,
                "category": place.get('category'),
                "image_url": place.get('image_url', ''),
                "location_link": place.get('location_link', ''),
                "ticket_link": place.get('ticket_link', ''),
                "ticket_booking": place.get('ticket_booking', False),
                "covers_meal": place.get('covers_meal', False),
                "logic_tags": place.get('logic_tags', []),
                "lat": place.get('lat', 0),
                "lng": place.get('lng', 0),
                "duration_minutes": duration,
                "price_level": place.get('price_level', 2),
                "description": place.get('description', ''),
            })
            current_time += duration / 60
            if type_name != "dinner":
                current_time += 0.25  
        
        if breakfast:
            add(breakfast, "breakfast")
            current_time += 0.25  
        else:
            current_time += 0.5
        
       
        time_until_lunch = self.lunch_time - current_time
        morning_activities = []
        travel_time = 0.25  

        for attr in attractions:
            duration_hours = self.get_place_duration(attr) / 60
            if time_until_lunch >= duration_hours + travel_time:
                morning_activities.append(attr)
                time_until_lunch -= (duration_hours + travel_time)
            else:
                break
        
        for attr in morning_activities:
            add(attr, "attraction")
        
        if current_time < self.lunch_time:
            current_time = self.lunch_time
        if lunch:
            add(lunch, "lunch")
            current_time += 0.25   
        
        time_until_dinner = self.dinner_time - current_time
        afternoon_activities = []
        
        remaining_attractions = [a for a in attractions if a not in morning_activities]
        for attr in remaining_attractions:
            duration_hours = self.get_place_duration(attr) / 60
            if time_until_dinner >= duration_hours + travel_time:
                afternoon_activities.append(attr)
                time_until_dinner -= (duration_hours + travel_time)
            else:
                break
        
        for attr in afternoon_activities:
            add(attr, "attraction")
        
        if current_time < self.dinner_time:
            current_time = self.dinner_time
        if dinner:
            add(dinner, "dinner")
        
        return {
            "day": day,
            "activities": activities,
            "daily_cost": sum(a.get('cost', 0) for a in activities),
            "morning_activities_count": len(morning_activities),
            "afternoon_activities_count": len(afternoon_activities)
        }
    
    async def create_trip_plan(self, city: str, days: int, interests: List[str], budget: float) -> Dict[str, Any]:
        
        all_places = self.get_places_from_db(city)
        
        if not all_places:
            return {"days": [], "total_cost": 0, "summary": f"No places found in {city}"}
        
        attractions = [p for p in all_places if not p.get('covers_meal', False)]
        meals = [p for p in all_places if p.get('covers_meal', False)]
        
        breakfast_places = [p for p in meals if "coffee" in p.get("logic_tags", []) or "mixed" in p.get("logic_tags", [])]
        lunch_places = [p for p in meals if "food" in p.get("logic_tags", []) or "mixed" in p.get("logic_tags", [])]
        
        if not breakfast_places:
            breakfast_places = meals
        if not lunch_places:
            lunch_places = meals
        
        selected_attractions = await self.ai_adapter.select_attractions(city, interests, budget, days, attractions)
        
        for p in selected_attractions:
            p["score"] = self.score_place(p, interests)
        selected_attractions.sort(key=lambda x: x["score"], reverse=True)
        
        clusters = self.cluster_by_location(selected_attractions)
        
        used_meal_ids = set()
        days_list = []
        
        attraction_index = 0
        
        for day in range(1, days + 1):
            available_minutes = self.calculate_available_time(day, True, True, True)
            
            remaining_attractions = selected_attractions[attraction_index:]
            max_activities = self.calculate_max_activities(remaining_attractions, available_minutes)
            
            cluster = clusters[day % len(clusters)]
            day_attractions = cluster[:max_activities]
            attraction_index += max_activities
            
            breakfast = self.pick_unique(breakfast_places, used_meal_ids)
            lunch = self.pick_unique(lunch_places, used_meal_ids)
            dinner = self.pick_unique(lunch_places, used_meal_ids)
            
            if lunch and "mixed" in lunch.get("logic_tags", []):
                dinner = None
            if breakfast and lunch and breakfast['id'] == lunch['id']:
                lunch = self.pick_unique(lunch_places, used_meal_ids)
            
            day_plan = self.create_daily_schedule(day, day_attractions, breakfast, lunch, dinner)
            days_list.append(day_plan)
        
        total_cost = sum(d.get("daily_cost", 0) for d in days_list)
        
        return {
            "days": days_list,
            "total_cost": total_cost,
            "summary": f"Amazing {days}-day trip to {city} exploring your interests!"
        }


async def generate_trip_plan(city: str, days: int, interests: List[str], budget: float) -> Dict[str, Any]:
    planner = TripPlanner()
    return await planner.create_trip_plan(city, days, interests, budget)
