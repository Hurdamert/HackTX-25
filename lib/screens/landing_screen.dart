import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/metronome.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _controller = MetronomeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Metronome Hub',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800, fontSize: 22, color: const Color(0xFF0F172A),
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () {}, // placeholder for Sign in
                      child: const Text('Sign in'),
                    )
                  ],
                ),
                const SizedBox(height: 12),

                // Hero card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your tempos, anywhere.',
                        style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Save tempos per song, import from text or sheet music, and keep them in sync.',
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 16),
                      // Metronome widget (compact for landing)
                      MetronomePanel(controller: _controller),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Feature chips
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: const [
                    _FeatureChip(icon: Icons.music_note, text: 'Tap tempo'),
                    _FeatureChip(icon: Icons.timeline, text: 'Accented downbeat'),
                    _FeatureChip(icon: Icons.cloud_sync, text: 'Cloud-ready'),
                  ],
                ),

                const SizedBox(height: 20),

                // CTA card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cs.primary, cs.primaryContainer]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Import songs from text or PDF',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text('Paste titles, we’ll auto-suggest BPM and time signature.',
                        style: GoogleFonts.inter(color: Colors.white.withValues()),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: cs.primary),
                        onPressed: () {}, // navigate to Import later
                        child: const Text('Try import'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon; final String text;
  const _FeatureChip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
      label: Text(text, style: const TextStyle(color: Color(0xFF0F172A))),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      backgroundColor: Colors.white,
    );
  }
}
