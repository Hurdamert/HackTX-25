import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple named tempo preset.
class TempoPreset {
  final String name;
  final int bpm;
  final int beatsPerBar;

  TempoPreset({required this.name, required this.bpm, required this.beatsPerBar});

  Map<String, dynamic> toJson() => {
        'name': name,
        'bpm': bpm,
        'beatsPerBar': beatsPerBar,
      };

  static TempoPreset fromJson(Map<String, dynamic> json) => TempoPreset(
        name: json['name'] as String,
        bpm: json['bpm'] as int,
        beatsPerBar: json['beatsPerBar'] as int,
      );
}

/// Key/value store for presets using SharedPreferences.
class TempoStore {
  static const _kKey = 'tempo_presets_v1';

  /// Load all presets.
  static Future<List<TempoPreset>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? const <String>[];
    return raw
        .map((s) => TempoPreset.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Save (insert/update) a preset by name.
  static Future<void> upsert(TempoPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll();
    final ix = list.indexWhere((p) => p.name.toLowerCase() == preset.name.toLowerCase());
    if (ix >= 0) {
      list[ix] = preset;
    } else {
      list.add(preset);
    }
    await prefs.setStringList(
      _kKey,
      list.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  /// Delete by name (optional helper).
  static Future<void> delete(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll();
    list.removeWhere((p) => p.name.toLowerCase() == name.toLowerCase());
    await prefs.setStringList(
      _kKey,
      list.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }
}
