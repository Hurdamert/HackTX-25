# backend/model.py
import os
import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow.keras import layers, models
from midi_features import extract_features

MODEL_PATH = "trained_model/tempo_model.keras"

def train_model(csv_path="data/tempo_dataset.csv", epochs=20, test_split=0.2):
    """
    Train a neural network to predict tempo from MIDI features.
    """
    df = pd.read_csv(csv_path)
    df = df.dropna()

    # ✅ Match your actual dataset columns
    feature_cols = ["note_density", "avg_pitch", "pitch_std", "avg_duration", "duration_std", "avg_velocity"]
    target_col = "tempo"

    # Safety check
    for col in feature_cols + [target_col]:
        if col not in df.columns:
            raise KeyError(f"Missing column in dataset: {col}")

    X = df[feature_cols].values
    y = df[target_col].values

    # Split into training & test sets
    split_idx = int(len(X) * (1 - test_split))
    X_train, X_test = X[:split_idx], X[split_idx:]
    y_train, y_test = y[:split_idx], y[split_idx:]

    # ✅ Define a neural net for regression
    model = models.Sequential([
        layers.Input(shape=(len(feature_cols),)),
        layers.Dense(128, activation="relu"),
        layers.Dense(64, activation="relu"),
        layers.Dense(32, activation="relu"),
        layers.Dense(1)  # single output: predicted tempo
    ])

    model.compile(optimizer="adam", loss="mse", metrics=["mae"])
    model.fit(X_train, y_train, validation_data=(X_test, y_test), epochs=epochs, batch_size=64)

    os.makedirs("trained_model", exist_ok=True)
    model.save(MODEL_PATH, save_format="keras")
    print(f"✅ Model trained and saved to {MODEL_PATH}")

def load_model():
    """Load trained model."""
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError("Model not found. Run train_model() first.")
    return tf.keras.models.load_model(MODEL_PATH)

def predict_tempo(midi_path):
    """Predict tempo from a new MIDI file."""
    model = load_model()
    features = extract_features(midi_path)

    # Only use matching feature columns
    feature_cols = ["note_density", "avg_pitch", "pitch_std", "avg_duration", "duration_std", "avg_velocity"]
    X = np.array([[features[col] for col in feature_cols]])

    tempo_pred = model.predict(X)[0][0]
    return tempo_pred

if __name__ == "__main__":
    train_model(epochs=25)
