from midi_features import extract_features
import os, pandas as pd, pretty_midi


def build_dataset(midi_dir="backend/data/lmd_matched", out_csv="backend/data/tempo_dataset.csv", limit=None):
    """
    Walks through all subdirectories of midi_dir, extracts features,
    estimates tempo, and saves to CSV.
    limit: optionally limit number of files for faster testing.
    """
    rows = []
    count = 0

    for root, _, files in os.walk(midi_dir):
        for file in files:
            if not file.endswith(".mid"):
                continue

            full_path = os.path.join(root, file)
            try:
                midi = pretty_midi.PrettyMIDI(full_path)
                tempo = midi.estimate_tempo()

                features = extract_features(full_path)
                features["tempo"] = tempo
                features["file"] = os.path.relpath(full_path, midi_dir)

                rows.append(features)
                count += 1

                if limit and count >= limit:
                    break

                if count % 100 == 0:
                    print(f"Processed {count} files...")

            except Exception as e:
                print(f"⚠️ Skipping {file}: {e}")

        if limit and count >= limit:
            break

    df = pd.DataFrame(rows)
    df.to_csv(out_csv, index=False)
    print(f"✅ Dataset built: {out_csv} ({len(df)} rows)")

if __name__ == "__main__":
    build_dataset(limit=2000)
