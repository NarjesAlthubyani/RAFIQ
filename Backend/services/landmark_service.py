import os
import requests
from dotenv import load_dotenv
from Backend.adapters.clip_recognizer import CLIPLandmarkRecognizer

env_path = os.path.join(os.path.dirname(__file__), "..", "..", ".env")
load_dotenv(env_path)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")  

recognizer = CLIPLandmarkRecognizer(
    ref_root=os.path.join(os.path.dirname(__file__), "..", "ref_images")
)
THRESHOLD = 0.55


def get_landmark_info(name: str):
    url = f"{SUPABASE_URL}/rest/v1/landmarks?name=eq.{name}&select=name,description"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
    }
    r = requests.get(url, headers=headers, timeout=10)

    if r.status_code == 200:
        data = r.json()
        if data:
            return data[0]
    return None


def recognize_landmark(filename: str, image_bytes: bytes):
    
    best_name, score = recognizer.recognize(image_bytes)

    if best_name is None or score is None or score < THRESHOLD:
        return {
            "recognized": False,
            "error": "Unable to Recognize Landmark",
            "confidence": float(score) if score is not None else 0.0
        }

    info = get_landmark_info(best_name)

    return {
        "recognized": True,
        "landmark_name": best_name,
        "confidence": float(score),
        "description": info["description"] if info else None
    }