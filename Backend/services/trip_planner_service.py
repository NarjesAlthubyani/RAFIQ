import math
from Backend.data.place_repository import place_repo
from Backend.adapters.ai_adapter import ai_client
from Backend.services.planning_services import (
    AttractionSelector,
    ClusterEngine,
    RouteOptimizer,
    ScheduleBuilder
)

class TripPlannerService:
    def __init__(self):
        # Initialize all planning services
        self.selector = AttractionSelector(ai_client)
        self.cluster_engine = ClusterEngine()
        self.route = RouteOptimizer()
        self.schedule = ScheduleBuilder()

    async def create_trip_plan(self, city, days, interests, budget):
        # Validate number of days
        if days <= 0:
            raise ValueError("Days must be greater than zero")

        # 1) Fetch all places for the selected city
        try:
            places = place_repo.get_places_by_city(city)
        except Exception as e:
            raise ValueError(f"Failed to fetch places for city '{city}': {e}")

        # Ensure city has places
        if not places:
            raise ValueError(f"No places found for city '{city}'")

        # Separate attractions from food places
        attractions = [p for p in places if not p.is_food]
        meals = [p for p in places if p.is_food]

        # Ensure attractions exist
        if len(attractions) == 0:
            raise ValueError("No attractions available for this city")

        # 2) Use AI to select the best attractions
        try:
            selected = await self.selector.select(
                city, interests, budget, days, attractions
            )
        except Exception as e:
            raise ValueError(f"AI attraction selection failed: {e}")

        # Ensure AI returned results
        if not selected:
            raise ValueError("AI returned an empty attraction list")

        # 3) Cluster selected attractions into groups for each day
        day_clusters = self.cluster_engine.cluster_for_days(selected, days)

        days_list = []

        # Global lists to prevent restaurant repetition across days
        cafes_global = [m for m in meals if m.food_type == "cafe"]
        restaurants_global = [m for m in meals if m.food_type == "restaurant"]

        # 4) Build each day's schedule
        for d in range(days):
            # Get attractions for this day
            day_places = day_clusters[d] if d < len(day_clusters) else []

            # Optimize route order for minimal travel distance
            optimized = self.route.optimize(day_places)

            # Copy remaining restaurants for this day
            cafes_day = cafes_global.copy()
            restaurants_day = restaurants_global.copy()

            # Build the full schedule 
            day_plan = self.schedule.build_day(day=d + 1, attractions=optimized, breakfast_candidates=cafes_day, lunch_candidates=restaurants_day, dinner_candidates=restaurants_day,)

            # Remove used restaurants from global lists to avoid repetition
            used_restaurants_names = {
                a["name"]
                for a in day_plan["activities"]
                if a["type"] in ["breakfast", "lunch", "dinner"]
            }

            cafes_global = [c for c in cafes_global if c.name not in used_restaurants_names]
            restaurants_global = [
                r for r in restaurants_global if r.name not in used_restaurants_names
            ]

            # Add completed day plan to final list
            days_list.append(day_plan)

        # 5) Calculate total trip cost
        try:
            total_cost = sum(day["daily_cost"] for day in days_list)
        except Exception:
            total_cost = 0

        # Return final structured trip plan
        return {
            "days": days_list,
            "total_cost": total_cost,
            "summary": f"A {days}-day trip to {city} tailored to your interests"
        }

# Global instance of the service
trip_planner_service = TripPlannerService()
