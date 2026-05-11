import json
import os
import re
import time
from dotenv import load_dotenv
from openai import OpenAI

# Load environment variables from .env file
load_dotenv()
OPENROUTER_KEY = os.getenv("OPENROUTER_API_KEY")

# Ensure API key exists
if not OPENROUTER_KEY:
    raise ValueError("Missing OPENROUTER_API_KEY in environment variables")

class AIAdapter:
    def __init__(self):
        try:
            # Initialize OpenRouter client
            self.client = OpenAI(
                api_key=OPENROUTER_KEY,
                base_url="https://openrouter.ai/api/v1"
            )
        except Exception as e:
            raise ConnectionError(f"Failed to initialize AI client: {e}")

        # Primary and fallback AI models
        self.model_primary = "nvidia/nemotron-nano-9b-v2"
        self.model_fallback = "meta-llama/llama-3.1-8b-instruct"

    # Extracts the JSON array found in the AI response
    def _extract_json_array(self, text: str):
        match = re.search(r"\[.*\]", text, re.S)
        if not match:
            raise ValueError("AI response does not contain a JSON array")
        return json.loads(match.group())

    # Sends a list of attractions to the AI model and asks it to pick the best ones
    async def select_attractions(self, city, interests, budget, days, attractions):

        # Limit attractions sent to AI for performance
        sample = attractions[:60]
        # Number of attractions needed based on trip length
        needed = max(1, days * 3)

        # Prepare payload with minimal required fields
        payload = [
            {
                "name": p.name,
                "category": p.category,
                "tags": p.tags,
                "duration": p.duration_minutes,
                "price_level": p.price_level,
            }
            for p in sample
        ]

        # AI prompt with clear instructions
        prompt = f"""
You are selecting attractions for a trip.

City: {city}
Interests: {interests}
Days: {days}
Budget: {budget}

Here is the list of available attractions:
{json.dumps(payload, ensure_ascii=False)}

Pick EXACTLY {needed} attractions by returning ONLY a JSON array of names.
Names MUST match exactly from the list above.
"""
        # Try primary model first, fallback if needed
        models_to_try = [self.model_primary, self.model_fallback]

        # Retry up to 3 times per model
        for model in models_to_try:
            for attempt in range(3):
                try:
                    # Send request to AI
                    res = self.client.chat.completions.create(
                        model=model,
                        messages=[
                            {"role": "system", "content": "Return only JSON"},
                            {"role": "user", "content": prompt},
                        ],
                        temperature=0.2,
                    )
                    # Extract raw text response
                    raw = res.choices[0].message.content
                    # Parse JSON array of attraction names
                    names = self._extract_json_array(raw)
                    # Match names to actual Place objects
                    selected = [p for p in attractions if p.name in names]
                    if not selected:
                        raise ValueError("AI returned no matching attractions")
                    
                    # Return only the required number
                    return selected[:needed]

                except Exception as e:
                    print(f"[AIAdapter] Model={model} attempt={attempt+1} failed: {e}")
                    time.sleep(1)
        # If all attempts fail, fallback to first N attractions
        print("[AIAdapter] All AI attempts failed — using fallback attractions.")
        return attractions[:needed]
    
# Global instance of AIAdapter
ai_client = AIAdapter()