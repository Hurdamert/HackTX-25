import pretty_midi
import numpy as np

def extract_features(file_path):
    midi_data = pretty_midi.PrettyMIDI(file_path)
    notes = []
    velocities = []
    durations = []

    for instrument in midi_data.instruments:
        for note in instrument.notes:
            notes.append(note.pitch)
            velocities.append(note.velocity)
            durations.append(note.end - note.start)

    features = {
        "note_density": len(notes) / midi_data.get_end_time(),
        "avg_pitch": np.mean(notes),
        "pitch_std": np.std(notes),
        "avg_duration": np.mean(durations),
        "duration_std": np.std(durations),
        "avg_velocity": np.mean(velocities)
    }
    return features
