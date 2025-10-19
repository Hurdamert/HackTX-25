# test_api_call.py
import requests

url = "http://127.0.0.1:8000/predict-tempo"
midi_path = "backend/data/lmd_matched/A/A/A/TRAAAGR128F425B14B/1d9d16a9da90c090809c153754823c2b.mid"

with open(midi_path, "rb") as f:
    files = {"file": (midi_path, f, "audio/midi")}
    response = requests.post(url, files=files)

print(response.status_code)
print(response.json())
