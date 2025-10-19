// lib/widgets/metronome.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

// storage helper (create at lib/services/tempo_store.dart)
import '../services/tempo_store.dart';

/// Metronome engine/controller
class MetronomeController {
  int bpm = 100;
  int beatsPerBar = 4;
  bool isRunning = false;
  final _rng = Random();

  final _pool = Soundpool.fromOptions(
    options: const SoundpoolOptions(streamType: StreamType.music),
  );

  int? _tickId;
  int? _tockId;
  Timer? _timer;
  int _beatIndex = 0;
  final _tapTimes = <int>[];

  Future<void> init() async {
    _tickId ??= await rootBundle.load('assets/tick.wav').then(_pool.load);
    _tockId ??= await rootBundle.load('assets/tock.wav').then(_pool.load);
  }

  // Self-correcting loop: schedule next tick from a fixed epoch to avoid drift.
  void start() {
    if (isRunning) return;
    isRunning = true;
    _beatIndex = 0;
    final periodMs = (60000 / bpm);
    final startEpoch = DateTime.now().microsecondsSinceEpoch;

    void scheduleNext(int n) {
      if (!isRunning) return;
      final targetUs = startEpoch + (periodMs * 1000 * n).round();
      final nowUs = DateTime.now().microsecondsSinceEpoch;
      final delay = Duration(microseconds: max(0, targetUs - nowUs));

      _timer = Timer(delay, () async {
        final accent = (_beatIndex % beatsPerBar) == 0;
        final id = accent ? _tockId : _tickId;
        if (id != null) {
          // tiny rate jitter avoids artifacts
          _pool.play(id, rate: 1.0 + (_rng.nextDouble() * 0.0001));
        }
        HapticFeedback.lightImpact(); // cosmetic, not timing-accurate

        _beatIndex++;
        scheduleNext(n + 1);
      });
    }

    scheduleNext(0);
  }

  void stop() {
    isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  void setBpm(int value) {
    bpm = value.clamp(20, 300);
    if (isRunning) {
      // restart to apply new period immediately
      stop();
      start();
    }
  }

  void setBeatsPerBar(int value) {
    beatsPerBar = value.clamp(1, 12);
  }

  // Tap-tempo: median-ish of recent intervals
  void tap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _tapTimes.add(now);
    if (_tapTimes.length > 5) _tapTimes.removeAt(0);
    if (_tapTimes.length >= 2) {
      final intervals = <int>[];
      for (int i = 1; i < _tapTimes.length; i++) {
        intervals.add(_tapTimes[i] - _tapTimes[i - 1]);
      }
      intervals.sort();
      final median = intervals[intervals.length ~/ 2];
      final newBpm = (60000 / median).round();
      setBpm(newBpm);
    }
  }

  Future<void> dispose() async {
    stop();
    await _pool.release();
  }
}

/// Press-and-hold icon button for ±BPM
class RepeatIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;      // single step (±1)
  final VoidCallback onRepeat;   // while held (±10)
  final Duration initialDelay;
  final Duration repeatInterval;

  const RepeatIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.onRepeat,
    this.initialDelay = const Duration(milliseconds: 250),
    this.repeatInterval = const Duration(milliseconds: 80),
  });

  @override
  State<RepeatIconButton> createState() => _RepeatIconButtonState();
}

class _RepeatIconButtonState extends State<RepeatIconButton> {
  Timer? _timer;

  void _startRepeat() {
    widget.onRepeat();
    _timer = Timer(widget.initialDelay, () {
      _timer = Timer.periodic(widget.repeatInterval, (_) => widget.onRepeat());
    });
  }

  void _stopRepeat() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPressStart: (_) => _startRepeat(),
      onLongPressEnd: (_) => _stopRepeat(),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(widget.icon, size: 28),
      ),
    );
  }
}

/// UI panel
class MetronomePanel extends StatefulWidget {
  final MetronomeController controller;
  const MetronomePanel({super.key, required this.controller});

  @override
  State<MetronomePanel> createState() => _MetronomePanelState();
}

class _MetronomePanelState extends State<MetronomePanel> {
  bool _ready = false;

  // Preset state
  List<TempoPreset> _presets = [];
  String? _selectedPresetName;

  @override
  void initState() {
    super.initState();
    widget.controller.init().then((_) => setState(() => _ready = true));
    _refreshPresets();
  }

  Future<void> _refreshPresets() async {
    final items = await TempoStore.loadAll();
    if (!mounted) return;
    setState(() {
      _presets = items;
      if (_selectedPresetName != null &&
          !_presets.any((p) => p.name == _selectedPresetName)) {
        _selectedPresetName = null;
      }
    });
  }

  void _nudgeBpm(int delta) {
    final next = (widget.controller.bpm + delta).clamp(20, 300);
    setState(() => widget.controller.setBpm(next as int));
  }

  Future<void> _saveTempoDialog() async {
    final c = widget.controller;
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save tempo'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Name (e.g., “Moonlight – 1st mvmt”)',
          ),
          onSubmitted: (_) => Navigator.pop(ctx, nameController.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    await TempoStore.upsert(TempoPreset(
      name: name,
      bpm: c.bpm,
      beatsPerBar: c.beatsPerBar,
    ));
    await _refreshPresets();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved “$name”')),
    );
  }

  void _applyPreset(TempoPreset p) {
    setState(() {
      widget.controller.setBeatsPerBar(p.beatsPerBar);
      widget.controller.setBpm(p.bpm);
      _selectedPresetName = p.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Readout row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('BPM', style: Theme.of(context).textTheme.titleMedium),
            Text('${c.bpm}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),

        const SizedBox(height: 8),

        // Centered tempo controls: tap = ±1, hold = auto-repeat ±10
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepeatIconButton(
              icon: Icons.arrow_back,
              onTap: () => _nudgeBpm(-1),
              onRepeat: () => _nudgeBpm(-10),
            ),
            SizedBox(
              width: 120, // keeps layout stable as digits change
              child: Center(
                child: Text(
                  '${c.bpm} BPM',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            RepeatIconButton(
              icon: Icons.arrow_forward,
              onTap: () => _nudgeBpm(1),
              onRepeat: () => _nudgeBpm(10),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Meter + transport
        Row(
          children: [
            const Text('Beats/Bar'),
            const SizedBox(width: 10),
            DropdownButton<int>(
              value: c.beatsPerBar,
              items: List.generate(12, (i) => i + 1)
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) => setState(() => c.setBeatsPerBar(v ?? 4)),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _ready
                  ? () {
                      setState(() {
                        c.isRunning ? c.stop() : c.start();
                      });
                    }
                  : null,
              icon: Icon(c.isRunning ? Icons.stop : Icons.play_arrow),
              label: Text(c.isRunning ? 'Stop' : 'Start'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _ready ? () => setState(c.tap) : null,
              child: const Text('Tap'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Presets: Save / Load
        Row(
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.save),
              onPressed: _ready ? _saveTempoDialog : null,
              label: const Text('Save tempo'),
            ),
            const SizedBox(width: 8),

            // Load dropdown
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  labelText: 'Load tempo',
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPresetName,
                    isExpanded: true,
                    hint: const Text('Select a saved tempo'),
                    items: _presets
                        .map((p) => DropdownMenuItem<String>(
                              value: p.name,
                              child: Text('${p.name}  •  ${p.bpm} BPM  •  ${p.beatsPerBar}/4'),
                            ))
                        .toList(),
                    onChanged: (name) {
                      if (name == null) return;
                      final p = _presets.firstWhere((e) => e.name == name);
                      _applyPreset(p);
                    },
                  ),
                ),
              ),
            ),

            // Optional quick delete of selected preset
            if (_selectedPresetName != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Delete selected',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final name = _selectedPresetName!;
                  await TempoStore.delete(name);
                  await _refreshPresets();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted “$name”')),
                  );
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
