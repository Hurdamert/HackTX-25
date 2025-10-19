import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:soundpool/soundpool.dart';

//i like men

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
        // play sound
        final accent = (_beatIndex % beatsPerBar) == 0;
        final id = accent ? _tockId : _tickId;
        if (id != null) _pool.play(id, rate: 1.0 + (_rng.nextDouble() * 0.0001)); // tiny rate jitter avoids artifacts
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
      stop();
      start();
    }
  }

  void setBeatsPerBar(int value) {
    beatsPerBar = value.clamp(1, 12);
  }

  // Tap-tempo: median of last 4 intervals
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
    if (_tickId != null) _pool.dispose();
    if (_tockId != null) _pool.dispose();
    await _pool.release();
  }
}

class MetronomePanel extends StatefulWidget {
  final MetronomeController controller;
  const MetronomePanel({super.key, required this.controller});

  @override
  State<MetronomePanel> createState() => _MetronomePanelState();
}

class _MetronomePanelState extends State<MetronomePanel> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    widget.controller.init().then((_) => setState(() => _ready = true));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BPM row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('BPM', style: Theme.of(context).textTheme.titleMedium),
            Text('${c.bpm}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
        Slider(
          value: c.bpm.toDouble(),
          min: 20, max: 300, divisions: 280,
          onChanged: (v) => setState(() => c.setBpm(v.round())),
        ),

        // Meter + controls
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
              onPressed: _ready ? (c.isRunning ? c.stop : c.start) : null,
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
      ],
    );
  }
}
