import os
import json
import time
from openai import OpenAI
from dotenv import load_dotenv
from typing import List, Dict, Any

load_dotenv()

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

if not OPENROUTER_API_KEY:
    raise Exception("❌ OPENROUTER_API_KEY not found in .env file!")

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=OPENROUTER_API_KEY,
    timeout=60.0, 
)

class AIEngineAPI:
    
    async def send_prompt(self, prompt: str) -> str:
        model = "openrouter/free"
    
        max_retries = 3
        for attempt in range(max_retries):
            try:
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
                if "429" in str(e) and attempt < max_retries - 1:
                  wait_time = (attempt + 1) * 2
                  time.sleep(wait_time)
                else:
                  return "[]"
    
        return "[]"

class AIAdapter:
    
    def __init__(self):
        self.ai_engine = AIEngineAPI()
    
    async def select_attractions(self, city: str, interests: List[str], budget: float, days: int, all_attractions: List[Dict]) -> List[Dict]:
        
        if not all_attractions:
            return []
        
        sample = all_attractions[:60]
        
        total_attractions_needed = days * 3
        
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
        
        if not response or response == "[]":
            return all_attractions[:total_attractions_needed]
        
        try:
            start = response.find('[')
            end = response.rfind(']') + 1
            if start != -1 and end > start:
                selected_names = json.loads(response[start:end])
                selected = [p for p in all_attractions if p['name'] in selected_names]
                return selected if selected else all_attractions[:total_attractions_needed]
        except Exception as e:
            print(f"❌ Parse error: {e}")
        
        return all_attractions[:total_attractions_needed]