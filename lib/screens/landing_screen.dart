import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/metronome.dart';
import './upload_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Metronome Hub',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: [
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignInPage()),
                            );
                          },
                          child: const Text('Sign in'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const UploadPage()),
                            );
                          },
                          child: const Text('Upload Sheet Music'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Hero section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save your tempos anywhere.',
                        style: GoogleFonts.inter(
                            fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Save tempos per song, import from text or sheet music, and keep them in sync.',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 16),
                      MetronomePanel(controller: _controller),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Feature chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _FeatureChip(icon: Icons.music_note, text: 'Tap tempo'),
                    _FeatureChip(icon: Icons.timeline, text: 'Accented downbeat'),
                  ],
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
  final IconData icon;
  final String text;
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

/// 🔐 Google Sign-In Page
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isSigningIn = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isSigningIn = true);

    try {
      // Google sign-in
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isSigningIn = false);
        return; // cancelled
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in as ${googleUser.displayName}')),
        );
        Navigator.pop(context); // go back to landing
      }
    } catch (e) {
      debugPrint('Error signing in: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sign-in failed')));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign in")),
      body: Center(
        child: _isSigningIn
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: Image.asset('assets/google_logo.png',
                    height: 24, width: 24),
                label: const Text("Sign in with Google"),
                onPressed: _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
      ),
    );
  }
}
