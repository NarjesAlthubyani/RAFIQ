from fastapi import APIRouter, UploadFile, File, HTTPException
from Backend.services.landmark_service import recognize_landmark

router = APIRouter(prefix="/api/landmarks", tags=["Landmarks"])

@router.post("/recognize")
async def recognize(image: UploadFile = File(...)):
    try:
        image_bytes = await image.read()
        return recognize_landmark(image.filename, image_bytes)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))