from fastapi import APIRouter, UploadFile, File, HTTPException
from Backend.services.landmark_service import recognize_landmark

router = APIRouter(prefix="/api/landmarks", tags=["Landmarks"])

@router.post("/recognize")
async def recognize(image: UploadFile = File(...)):
    try:
        # Read the uploaded image and send it to the recognition service
        image_bytes = await image.read()
        return recognize_landmark(image.filename, image_bytes)
    except ValueError as e:
        # Return a clear error response if the image cannot be processed
        raise HTTPException(status_code=400, detail=str(e))