import os
import math
from supabase import create_client
from dotenv import load_dotenv
from typing import List, Dict, Any, Optional
from Backend.services.ai_adapter import AIAdapter

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


class TripPlanner:

    def __init__(self):
        self.ai_adapter = AIAdapter()
        self.day_start_hour = 9
        self.day_end_hour = 21

    # ---------------- DB ----------------
    def get_places_from_db(self, city: str) -> List[Dict]:
        response = supabase.table("saudi_places").select("*").eq("city", city).execute()

        for place in response.data:
            tags = place.get("tags", []) or []
            category = str(place.get("category", "")).lower()

            place["all_tags"] = list(set(
                [t.lower() for t in tags] + ([category] if category else [])
            ))

        return response.data

    # ---------------- CORE ----------------
    def get_place_duration(self, place: Dict) -> int:
        return max(30, int(place.get("duration_minutes", 120)))

    def place_distance(self, p1: Dict, p2: Dict) -> float:
        if not p1 or not p2:
            return 9999

        lat1, lng1 = p1.get("lat", 0), p1.get("lng", 0)
        lat2, lng2 = p2.get("lat", 0), p2.get("lng", 0)

        if not lat1 or not lng1 or not lat2 or not lng2:
            return 9999

        R = 6371
        lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lng1, lat2, lng2])
        dlat = lat2 - lat1
        dlon = lon2 - lon1

        a = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
        return R * 2 * math.asin(math.sqrt(a))

    def calculate_travel_time(self, p1: Dict, p2: Dict) -> int:
        distance = self.place_distance(p1, p2)

        if distance <= 1: return 5
        if distance <= 3: return 10
        if distance <= 5: return 15
        if distance <= 10: return 20
        return 30

    def estimate_cost(self, place: Dict) -> int:
        return place.get("price_level", 2) * 60

    # ---------------- INTEREST SCORE ----------------
    def score_place(self, place: Dict, interests: List[str]) -> float:
        tags = set(place.get("all_tags", []))
        interests = set([i.lower() for i in interests])

        score = 0
        for i in interests:
            for t in tags:
                if i == t:
                    score += 5
                elif i in t or t in i:
                    score += 2

        return score

    # ---------------- FOOD LOGIC ----------------
    def is_food(self, place: Dict) -> bool:
        category = str(place.get("category", "")).lower()
        return any(x in category for x in ["food", "restaurant", "cafe", "coffee"])

    def get_food_type(self, place: Dict) -> str:
        category = str(place.get("category", "")).lower()

        if "cafe" in category or "coffee" in category:
            return "cafe"
        if "restaurant" in category or "food" in category:
            return "restaurant"

        return "other"

    def covers_meal(self, place: Dict) -> bool:
        return place.get("covers_meal", False)

    # ---------------- CLUSTER ----------------
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

                if self.place_distance(places[i], places[j]) <= 3:
                    cluster.append(places[j])
                    used[j] = True

            clusters.append(cluster)

        return clusters

    # ---------------- DAILY ----------------
    def create_daily_schedule(self, day, attractions, breakfast, lunch, dinner):
        activities = []
        current_time = self.day_start_hour
        last_place = None
        last_was_food = False

        def add(place, type_name):
            nonlocal current_time, last_place, last_was_food

            travel = self.calculate_travel_time(last_place, place) if last_place else 0
            current_time += travel / 60

            duration = self.get_place_duration(place)

            if current_time + duration / 60 > self.day_end_hour:
                return False

            # ❌ منع food ورا بعض
            if self.is_food(place) and last_was_food:
                return False

            activities.append({
                "time": f"{int(current_time):02d}:{int((current_time % 1) * 60):02d}",
                "name": place["name"],
                "type": type_name,
                "duration": duration,
                "cost": self.estimate_cost(place),
                "category": place.get("category"),
                "image_url": place.get("image_url", ""),
                "location_link": place.get("location_link", ""),
                "ticket_link": place.get("ticket_link", ""),
                "ticket_booking": place.get("ticket_booking", False),
            })

            current_time += duration / 60
            last_place = place
            last_was_food = self.is_food(place)

            return True

        # breakfast (☕)
        if breakfast:
            add(breakfast, "breakfast")

        # attractions
        for attr in attractions:
            if self.covers_meal(attr):
                add(attr, "attraction")
                last_was_food = True
                continue

            add(attr, "attraction")

        # lunch (🍽️)
        if lunch and not last_was_food:
            add(lunch, "lunch")

        # dinner (🍽️)
        if dinner and not last_was_food:
            add(dinner, "dinner")

        return {
            "day": day,
            "activities": activities,
            "daily_cost": sum(a["cost"] for a in activities)
        }

    # ---------------- MAIN ----------------
    async def create_trip_plan(self, city, days, interests, budget):
        all_places = self.get_places_from_db(city)

        attractions = [p for p in all_places if not self.is_food(p)]
        meals = [p for p in all_places if self.is_food(p)]

        selected = await self.ai_adapter.select_attractions(city, interests, budget, days, attractions)

        for p in selected:
            p["score"] = self.score_place(p, interests)

        selected.sort(key=lambda x: x["score"], reverse=True)

        clusters = self.cluster_by_location(selected)

        used = set()
        days_list = []
        total_cost = 0

        # تقسيم meals
        cafes = [p for p in meals if self.get_food_type(p) == "cafe"]
        restaurants = [p for p in meals if self.get_food_type(p) == "restaurant"]

        for d in range(1, days + 1):

            cluster = clusters[d-1] if d-1 < len(clusters) else []

            day_attractions = [p for p in cluster if p["id"] not in used][:4]

            for p in day_attractions:
                used.add(p["id"])

            breakfast = cafes[d-1] if d-1 < len(cafes) else None
            lunch = restaurants[d-1] if d-1 < len(restaurants) else None
            dinner = restaurants[d] if d < len(restaurants) else None

            day_plan = self.create_daily_schedule(d, day_attractions, breakfast, lunch, dinner)

            days_list.append(day_plan)
            total_cost += day_plan["daily_cost"]

        return {
            "days": days_list,
            "total_cost": total_cost,
            "summary": f"Amazing {days}-day trip to {city}"
        }


async def generate_trip_plan(city, days, interests, budget):
    planner = TripPlanner()
    return await planner.create_trip_plan(city, days, interests, budget)