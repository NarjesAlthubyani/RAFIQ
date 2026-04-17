import os
from dotenv import load_dotenv
env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
load_dotenv(env_path)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from Backend.routers.landmarks_router import router as landmarks_router
from Backend.routers.activities import router as activities_router



app = FastAPI(title="RAFIQ Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def home():
    return {"message": "Backend is working"}

app.include_router(activities_router, prefix="/activities", tags=["activities"])
app.include_router(landmarks_router)