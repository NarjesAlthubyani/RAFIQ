import os
import io
import torch
from PIL import Image
from transformers import CLIPProcessor, CLIPModel

class CLIPLandmarkRecognizer:
    def __init__(self, ref_root="ref_images"):
        # Use GPU if available for faster processing
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        # Load pre-trained CLIP model
        self.model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").to(self.device)
        self.processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

        self.ref_root = ref_root
        self.ref = []  #Store (landmark_name, embedding)
        self._load_reference_images()

    def _embed(self, img: Image.Image) -> torch.Tensor:
        
        inputs = self.processor(images=img, return_tensors="pt")
        pixel_values = inputs["pixel_values"].to(self.device)

        with torch.no_grad():
            vision_out = self.model.vision_model(pixel_values=pixel_values, return_dict=True)

            pooled = vision_out.pooler_output
            if pooled is None:
                pooled = vision_out.last_hidden_state[:, 0, :]

            emb = self.model.visual_projection(pooled)

       # Normalize embedding to make similarity comparison consistent
        emb = emb / emb.norm(dim=-1, keepdim=True)
        return emb.squeeze(0).cpu()

    def _load_reference_images(self):
        if not os.path.isdir(self.ref_root):
            raise RuntimeError(f"Reference folder not found: {self.ref_root}")

        for landmark_name in os.listdir(self.ref_root):
            folder = os.path.join(self.ref_root, landmark_name)
            if not os.path.isdir(folder):
                continue

            for fname in os.listdir(folder):
                if not fname.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
                    continue

                path = os.path.join(folder, fname)
                img = Image.open(path).convert("RGB")

                # Convert each reference image into an embedding
                emb = self._embed(img)
                self.ref.append((landmark_name, emb))

        if not self.ref:
            raise RuntimeError("No reference images found inside ref_images/")

    def recognize(self, uploaded_image_bytes: bytes) -> tuple[str, float]:
        # Convert uploaded image to embedding
        img = Image.open(io.BytesIO(uploaded_image_bytes)).convert("RGB")
        query = self._embed(img)

        best_name = "Unknown"
        best_score = -1.0

        # Compare uploaded image with all stored reference embeddings
        for name, emb in self.ref:
            score = float(torch.dot(query, emb))  # similarity score
            if score > best_score:
                best_score = score
                best_name = name

        

        return (best_name, best_score)