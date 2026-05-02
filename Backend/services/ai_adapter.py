import os
import json
import time
from openai import OpenAI
from dotenv import load_dotenv
from typing import List, Dict, Any

# Load environment variables from .env file
load_dotenv()

# Get OpenRouter API key from environment variables
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

# Validate API key exists before proceeding
if not OPENROUTER_API_KEY:
    raise Exception("❌ OPENROUTER_API_KEY not found in .env file!")

# Initialize OpenAI client with OpenRouter base URL
client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=OPENROUTER_API_KEY,
    timeout=60.0, 
)

class AIEngineAPI:
    
    async def send_prompt(self, prompt: str) -> str:
        """Send a prompt to the AI and return the response."""
        
        model = "nvidia/nemotron-nano-9b-v2"
    
        max_retries = 3
        for attempt in range(max_retries):
            try:
                # Send request to OpenRouter API
                response = client.chat.completions.create(
                    model=model,
                    messages=[
                        {"role": "system", "content": "You are an expert travel planner for Saudi Arabia. Respond only with valid JSON."},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.3,
                    max_tokens=2000,
                    timeout=90.0,
                )
                result = response.choices[0].message.content
                return result
            except Exception as e:
                # Handle rate limit 
                if "429" in str(e) and attempt < max_retries - 1:
                    wait_time = (attempt + 1) * 2
                    time.sleep(wait_time)
                else:
                    # Return empty array fallback for other errors
                    return "[]"
    
        return "[]"

class AIAdapter:
    
    def __init__(self):
        """Initialize with AI engine instance."""
        self.ai_engine = AIEngineAPI()
    
    async def select_attractions(self, city: str, interests: List[str], budget: float, days: int, all_attractions: List[Dict]) -> List[Dict]:
        """Select relevant attractions based on user preferences and constraints."""
        
        # Return empty list if no attractions available
        if not all_attractions:
            return []
        
        # Limit sample size to prevent token overflow
        sample = all_attractions[:60]
        
        # Calculate target number: 4 attractions per day
        total_attractions_needed = days * 4
        
        # Build prompt for AI
        prompt = f"""
You are a travel planner for {city}, Saudi Arabia.

USER INTERESTS: {', '.join(interests)}
Budget: {budget} SAR
Trip duration: {days} days
Select {total_attractions_needed} attractions.

Available attractions:
{json.dumps([{'name': p['name'], 'category': p.get('category', '')} for p in sample], indent=2)}

Return ONLY JSON array of names:
["Place 1", "Place 2", "Place 3"]
"""
        response = await self.ai_engine.send_prompt(prompt)
        
        # Fallback: return first N attractions if AI fails
        if not response or response == "[]":
            return all_attractions[:total_attractions_needed]
        
        try:
            # Extract JSON array from response 
            start = response.find('[')
            end = response.rfind(']') + 1
            if start != -1 and end > start:
                selected_names = json.loads(response[start:end])
                selected = [p for p in all_attractions if p['name'] in selected_names]
                return selected if selected else all_attractions[:total_attractions_needed]
        except Exception as e:
            print(f"❌ Parse error: {e}")
        
        # Final fallback
        return all_attractions[:total_attractions_needed]