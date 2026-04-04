from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from Backend.routers.landmarks_router import router as landmarks_router

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

app.include_router(landmarks_router)