import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'landing_screen.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Sheet Music"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LandingScreen()),
            );
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Upload your sheet music file",
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: implement file picker & ML processing later
                },
                icon: const Icon(Icons.upload_file),
                label: const Text("Choose File"),
              ),
              const SizedBox(height: 20),
              Text(
                "Accepted formats: PDF, MusicXML, MIDI",
                style: GoogleFonts.inter(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
