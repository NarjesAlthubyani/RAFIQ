import os
import json
from google import genai
from google.genai import types
from dotenv import load_dotenv
from typing import List, Dict, Any

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

client = genai.Client(api_key=GEMINI_API_KEY)

class AIEngineAPI:
    
    async def send_prompt(self, prompt: str) -> str:
        try:
            response = client.models.generate_content(
                model='gemini-2.0-flash',
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.3,
                    max_output_tokens=2000,
                )
            )
            return response.text
        except Exception as e:
            print(f"AIEngineAPI error: {e}")
            return ""

class AIAdapter:
    
    def __init__(self):
        self.ai_engine = AIEngineAPI()
    
    async def select_attractions(self, city: str, interests: List[str], budget: float, days: int, all_attractions: List[Dict]) -> List[Dict]:
        
        if not all_attractions:
            return []
        
        sample = all_attractions[:60]
        
        prompt = f"""
You are a travel planner for {city}, Saudi Arabia.

User interests: {', '.join(interests)}
Budget: {budget} SAR
Trip duration: {days} days

Available attractions:
{json.dumps([{'name': p['name'], 'category': p.get('category', ''), 'price': p.get('price_level', 2)} for p in sample], indent=2)}

Select the best {days * 3} attractions that match the user's interests and budget.

Return ONLY JSON array of names:
["Place 1", "Place 2", "Place 3"]
"""
        response = await self.ai_engine.send_prompt(prompt)
        
        try:
            start = response.find('[')
            end = response.rfind(']') + 1
            if start != -1 and end > start:
                selected_names = json.loads(response[start:end])
                selected = [p for p in all_attractions if p['name'] in selected_names]
                return selected if selected else all_attractions[:days*3]
        except Exception as e:
            print(f"AI selection error: {e}")
        
        return all_attractions[:days*3]