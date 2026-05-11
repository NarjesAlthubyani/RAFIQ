import math
from torch import add
from Backend.routers.activities import activities

# AttractionSelector
class AttractionSelector:
    def __init__(self, ai_client):
        # Store reference to AI client
        self.ai = ai_client

    async def select(self, city, interests, budget, days, attractions):
        # Ensure attractions list is not empty
        if not attractions:
            raise ValueError("No attractions available for selection")
        try:
            # Delegate selection to AI model
            return await self.ai.select_attractions(city, interests, budget, days, attractions)
        
        except Exception as e:
            # Wrap AI errors with a clear message
            raise ValueError(f"AI attraction selection failed: {e}")
        

# Clusters attractions based on geographic distance
class ClusterEngine:
    def __init__(self, base_radius_km: float = 3.0):
        # Base radius used to determine cluster grouping
        self.base_radius = base_radius_km

    def _dist_km(self, a, b):
        # Calculate haversine distance between two coordinates
        if not a or not b:
            return 999
        try:
            R = 6371  # Earth radius in km
            dlat = math.radians(b.lat - a.lat)
            dlon = math.radians(b.lng - a.lng)
            x = math.sin(dlat/2)**2 + math.cos(math.radians(a.lat)) * \
                math.cos(math.radians(b.lat)) * math.sin(dlon/2)**2
            return 2 * R * math.asin(math.sqrt(x))
        except Exception:
            return 999

    def cluster_for_days(self, places, days: int):
        # Return empty result if no places provided
        if not places:
            return []

        # Dynamically adjust clustering radius based on number of places
        radius = max(2.0, min(8.0, self.base_radius * (len(places) / (days * 4))))

        clusters = []
        used = [False] * len(places)

        # Build clusters by grouping nearby places
        for i in range(len(places)):
            if used[i]:
                continue

            cluster = [places[i]]
            used[i] = True

            # Add nearby places to the same cluster
            for j in range(i + 1, len(places)):
                if used[j]:
                    continue
                if self._dist_km(places[i], places[j]) <= radius:
                    cluster.append(places[j])
                    used[j] = True

            clusters.append(cluster)

        # Sort clusters by size 
        clusters.sort(key=len, reverse=True)

        # Flatten clusters and distribute evenly across days
        flat = [p for c in clusters for p in c]
        per_day = max(1, math.ceil(len(flat) / days))
        result = []

        for d in range(days):
            start = d * per_day
            end = start + per_day
            result.append(flat[start:end])

        return result

# Optimizes the order of attractions to minimize travel distance
class RouteOptimizer:
    def _dist(self, a, b):
        # Simple Euclidean distance for ordering
        if not a or not b:
            return 999
        try:
            return ((a.lat - b.lat)**2 + (a.lng - b.lng)**2) ** 0.5
        except Exception:
            return 999

    def _nearest_neighbor(self, places):
        # Greedy algorithm to build an initial route
        if not places:
            return []
        ordered = [places[0]]
        rem = places[1:]
        while rem:
            last = ordered[-1]
            nxt = min(rem, key=lambda p: self._dist(last, p))
            ordered.append(nxt)
            rem.remove(nxt)
        return ordered

    def _two_opt(self, route):
        # 2-opt algorithm to refine the route
        if len(route) < 4:
            return route

        best = route[:]
        improved = True

        while improved:
            improved = False
            for i in range(1, len(best) - 2):
                for j in range(i + 1, len(best) - 1):
                    new_route = best[:]
                    new_route[i:j] = reversed(new_route[i:j])
                    if self._route_length(new_route) < self._route_length(best):
                        best = new_route
                        improved = True
        return best

    def _route_length(self, route):
        # Compute total route distance
        return sum(self._dist(route[i], route[i+1]) for i in range(len(route)-1))

    def optimize(self, places):
        # Build initial route then refine it
        nn = self._nearest_neighbor(places)
        return self._two_opt(nn)

# Helper distance function used by MealPlanner
def _dist(a, b):
    if not a or not b:
        return 999
    try:
        return ((a.lat - b.lat)**2 + (a.lng - b.lng)**2) ** 0.5
    except Exception:
        return 999

# Selects the best meal locations based on distance & budget
class MealPlanner:
    def __init__(self):
        # Time thresholds for meals
        self.LUNCH_START = 12 * 60
        self.DINNER_START = 18 * 60

    def _score(self, place, prev_place, next_place, budget_level):
        # Compute score based on distance & budget match
        try:
            dist_prev = _dist(prev_place, place) if prev_place else 0
            dist_next = _dist(place, next_place) if next_place else 0
            distance_score = dist_prev + dist_next
            budget_score = abs(place.price_level - budget_level) * 10
            return distance_score + budget_score
        except Exception:
            return 999999

    def pick_best(self, places, prev_place, next_place, budget_level):
        # Pick place with lowest score
        if not places:
            return None
        try:
            return min(places,key=lambda p: self._score(p, prev_place, next_place, budget_level),)
        except Exception:
            return places[0]

    def choose_breakfast(self, cafes, first_activity):
        return self.pick_best(cafes, None, first_activity, budget_level=1)

    def choose_lunch(self, restaurants, prev_activity, next_activity, current_time):
        if current_time < self.LUNCH_START:
            return None
        return self.pick_best(restaurants, prev_activity, next_activity, budget_level=2)

    def choose_dinner(self, restaurants, prev_activity, current_time):
        if current_time < self.DINNER_START:
            return None
        return self.pick_best(restaurants, prev_activity, None, budget_level=3)

# Builds a full day schedule including attractions & meals
class ScheduleBuilder:

    def __init__(self):
        # Day start/end times in minutes
        self.day_start = 9 * 60
        self.day_end = 21 * 60
        self.meal_planner = MealPlanner()

    def _travel_time_minutes(self, a, b):
        # Convert distance to approximate travel time
        d = _dist(a, b)
        return int(d * 4)

    def build_day(self, day, attractions, breakfast_candidates, lunch_candidates, dinner_candidates):
        activities = []
        current = self.day_start

        def add(place, type_, prev_place=None):
            # Add an activity to the schedule with travel & duration
            nonlocal current
            if not place:
                return

            travel = self._travel_time_minutes(prev_place, place) if prev_place else 0
            current += travel

            try:
                duration = place.duration_minutes or 60
                cost = place.price_level * 60
            except Exception:
                duration = 60
                cost = 0

            # Skip if activity exceeds end of day
            if current + duration > self.day_end:
                return {"day": day,"activities": activities,"daily_cost": sum(a["cost"] for a in activities)}

            activities.append({
                "time": f"{current//60:02d}:{current%60:02d}",
                "name": getattr(place, "name", "Unknown"),
                "type": type_,
                "duration": duration,
                "cost": cost,
                "category": getattr(place, "category", ""),
                "image_url": getattr(place, "image_url", ""),
                "location_link": getattr(place, "location_link", ""),
                "ticket_link": getattr(place, "ticket_link", ""),
                "ticket_booking": getattr(place, "ticket_booking", False),
            })

            current += duration

        # BREAKFAST
        first_activity = attractions[0] if attractions else None
        breakfast = self.meal_planner.choose_breakfast(breakfast_candidates, first_activity)
        add(breakfast, "breakfast")

        # Prevent breakfast duplication
        if breakfast and breakfast in breakfast_candidates:
            breakfast_candidates.remove(breakfast)

        # ATTRACTIONS & LUNCH
        for i, act in enumerate(attractions):
            prev_act = attractions[i - 1] if i > 0 else breakfast
            next_act = attractions[i + 1] if i + 1 < len(attractions) else None

            add(act, "attraction", prev_place=prev_act)

            lunch = self.meal_planner.choose_lunch(
                lunch_candidates,
                prev_activity=act,
                next_activity=next_act,
                current_time=current
            )

            if lunch:
                add(lunch, "lunch", prev_place=act)

                # Prevent lunch duplication
                if lunch in lunch_candidates:
                    lunch_candidates.remove(lunch)

        # DINNER
        last_activity = attractions[-1] if attractions else breakfast
        dinner = self.meal_planner.choose_dinner(
            dinner_candidates,
            prev_activity=last_activity,
            current_time=current
        )

        if dinner:
            # 1) Prevent dinner if last activity was a meal
            if activities and activities[-1]["type"] in ["lunch", "dinner"]:
                dinner = None

            # 2) Prevent dinner if same restaurant was used earlier in the day
            if dinner and any(a["name"] == dinner.name for a in activities):
                dinner = None

            # 3) Prevent dinner if too late (after 8 PM)
            if dinner and current > (20 * 60):
                dinner = None

        if dinner:
            add(dinner, "dinner", prev_place=last_activity)
            if dinner in dinner_candidates:
                dinner_candidates.remove(dinner)

        return {
            "day": day,
            "activities": activities,
            "daily_cost": sum(a["cost"] for a in activities)
        }
