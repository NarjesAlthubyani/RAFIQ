import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

# Read Supabase credentials from environment variables
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")

# Validate required environment variables
if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("Missing SUPABASE_URL or SUPABASE_ANON_KEY in environment variables")

class Place:
    def __init__(self, data: dict):
        try:
            self.id = data["id"]
            self.name = data["name"]
            self.lat = float(data["lat"])   
            self.lng = float(data["lng"])   
        except KeyError as e:
            raise ValueError(f"Missing required field in place data: {e}")
        except Exception as e:
            raise ValueError(f"Invalid coordinate format: {e}")

        self.city = data.get("city", "")
        self.category = data.get("category", "")
        self.tags = data.get("tags", []) or []
        self.duration_minutes = data.get("duration_minutes", 120)
        self.price_level = data.get("price_level", 2)
        self.image_url = data.get("image_url", "")
        self.location_link = data.get("location_link", "")
        self.ticket_link = data.get("ticket_link", "")
        self.ticket_booking = data.get("ticket_booking", False)

    @property
    def is_food(self):
        # Determine if place is a food-related location
        c = self.category.lower()
        return "restaurant" in c or "cafe" in c or "coffee" in c

    @property
    def food_type(self):
        # Classify food type for meal planning
        c = self.category.lower()
        if "cafe" in c:
            return "cafe"
        if "restaurant" in c:
            return "restaurant"
        return "other"

class SupabasePlaceRepository:
    def __init__(self):
        # Initialize Supabase client
        try:
            self.client = create_client(SUPABASE_URL, SUPABASE_KEY)
        except Exception as e:
            raise ConnectionError(f"Failed to initialize Supabase client: {e}")

    def get_places_by_city(self, city: str):
        # Validate input
        if not city:
            raise ValueError("City name cannot be empty")

        # Query Supabase for places in the given city
        try:
            res = (
                self.client
                .table("saudi_places")
                .select("*")
                .eq("city", city)
                .execute()
            )
        except Exception as e:
            raise ConnectionError(f"Supabase query failed: {e}")

        # Validate response structure
        if not hasattr(res, "data") or res.data is None:
            raise ValueError("Invalid Supabase response format")

        # Handle empty results
        if len(res.data) == 0:
            print(f"[PlaceRepository] Warning: No places found for city '{city}'")
            return []

        # Convert raw data into Place objects
        try:
            return [Place(p) for p in res.data]
        except Exception as e:
            raise ValueError(f"Failed to parse place data: {e}")

# Global repository instance
place_repo = SupabasePlaceRepository()
