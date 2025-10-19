# backend/app.py
from fastapi import FastAPI, UploadFile
from model import predict_tempo
import shutil, os

app = FastAPI()

@app.post("/predict-tempo")
async def predict_tempo_endpoint(file: UploadFile):
    os.makedirs("temp", exist_ok=True)
    temp_path = f"temp/{file.filename}"

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
