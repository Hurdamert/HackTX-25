# # backend/app.py
# from fastapi import FastAPI, UploadFile
# from model import predict_tempo
# import shutil, os

# app = FastAPI()

# @app.post("/backend/predict-tempo")
# async def predict_tempo_endpoint(file: UploadFile):
#     os.makedirs("temp", exist_ok=True)
#     temp_path = f"temp/{file.filename}"

#     # Save uploaded MIDI file
#     with open(temp_path, "wb") as buffer:
#         shutil.copyfileobj(file.file, buffer)

#     # Predict tempo
#     tempo = predict_tempo(temp_path)

#     # Clean up
#     os.remove(temp_path)
#     return {"predicted_tempo": round(float(tempo), 2)}

# @app.get("/")
# async def root():
#     return {"status": "Backend running successfully!"}

from fastapi import FastAPI, UploadFile
from backend.model import predict_tempo
import shutil, os
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # or specify your Flutter web domain later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/backend/predict-tempo")
async def predict_tempo_endpoint(file: UploadFile):
    temp_dir = os.path.join("backend", "temp")
    os.makedirs(temp_dir, exist_ok=True)
    temp_path = os.path.join(temp_dir, file.filename)

    # Save uploaded MIDI file
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Predict tempo
    tempo = predict_tempo(temp_path)

    # Clean up
    os.remove(temp_path)
    return {"predicted_tempo": round(float(tempo), 2)}

@app.get("/")
async def root():
    return {"status": "Backend running successfully!"}
