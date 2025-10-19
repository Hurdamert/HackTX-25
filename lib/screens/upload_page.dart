// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'landing_screen.dart';

// class UploadPage extends StatelessWidget {
//   const UploadPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Upload Sheet Music"),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const LandingScreen()),
//             );
//           },
//         ),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "Upload your sheet music file",
//                 style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
//               ),
//               const SizedBox(height: 20),
//               OutlinedButton.icon(
//                 onPressed: () {
//                   // TODO: implement file picker & ML processing later
//                 },
//                 icon: const Icon(Icons.upload_file),
//                 label: const Text("Choose File"),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 "Accepted formats: PDF, MusicXML, MIDI",
//                 style: GoogleFonts.inter(color: Colors.grey[700]),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'dart:convert';
// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'landing_screen.dart';

// class UploadPage extends StatefulWidget {
//   const UploadPage({super.key});

//   @override
//   State<UploadPage> createState() => _UploadPageState();
// }

// class _UploadPageState extends State<UploadPage> {
//   String? selectedFileName;
//   String? predictedTempo;
//   bool isLoading = false;

//   Future<void> pickAndUploadFile() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['mid', 'midi'],
//         withData: true, // ✅ ensures bytes are available on web
//       );

//       if (result == null) return;

//       final file = result.files.single;
//       setState(() {
//         selectedFileName = file.name;
//         isLoading = true;
//         predictedTempo = null;
//       });

//       const apiUrl = "http://52.200.120.45:8000/backend/predict-tempo";
//       final uri = Uri.parse(apiUrl);

//       final request = http.MultipartRequest("POST", uri)
//         ..files.add(http.MultipartFile.fromBytes(
//           "file",
//           file.bytes!,
//           filename: file.name,
//         ));

//       final response = await request.send();
//       final respStr = await response.stream.bytesToString();

//       if (response.statusCode == 200) {
//         final jsonResp = json.decode(respStr);
//         setState(() {
//           predictedTempo = jsonResp["predicted_tempo"].toString();
//         });
//       } else {
//         setState(() {
//           predictedTempo = "Error: ${response.statusCode}";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         predictedTempo = "Upload failed: $e";
//       });
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Upload Sheet Music"),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const LandingScreen()),
//             );
//           },
//         ),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "Upload your sheet music file",
//                 style: GoogleFonts.inter(
//                     fontSize: 22, fontWeight: FontWeight.w700),
//               ),
//               const SizedBox(height: 20),
//               OutlinedButton.icon(
//                 onPressed: isLoading ? null : pickAndUploadFile,
//                 icon: const Icon(Icons.upload_file),
//                 label: Text(
//                   selectedFileName == null ? "Choose File" : "Re-upload File",
//                 ),
//               ),
//               const SizedBox(height: 20),
//               if (isLoading) const CircularProgressIndicator(),
//               if (selectedFileName != null && !isLoading)
//                 Text(
//                   "Selected: $selectedFileName",
//                   style: GoogleFonts.inter(fontSize: 16),
//                 ),
//               const SizedBox(height: 20),
//               if (predictedTempo != null)
//                 Text(
//                   predictedTempo!.startsWith("Error") ||
//                           predictedTempo!.startsWith("Upload")
//                       ? predictedTempo!
//                       : "Predicted Tempo: $predictedTempo BPM",
//                   style: GoogleFonts.inter(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: predictedTempo!.startsWith("Error")
//                         ? Colors.red
//                         : Colors.green[700],
//                   ),
//                 ),
//               const SizedBox(height: 20),
//               Text(
//                 "Accepted formats: PDF, MusicXML, MIDI",
//                 style: GoogleFonts.inter(color: Colors.grey[700]),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'landing_screen.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String result = "";

  Future<void> uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mid', 'midi'],
      withData: true, // <-- important for Flutter Web!
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    final filename = file.name;

    if (bytes == null) {
      setState(() => this.result = "No bytes found in file.");
      return;
    }

    try {
      var uri = Uri.parse("http://52.200.120.45:8000/backend/predict-tempo");
      var request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ));

      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        setState(() => this.result = "✅ Success: $respStr");
      } else {
        setState(() => this.result =
            "❌ Failed (${response.statusCode}): ${response.reasonPhrase}");
      }
    } catch (e) {
      setState(() => this.result = "Upload failed: $e");
    }
  }

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
                style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: uploadFile,
                icon: const Icon(Icons.upload_file),
                label: const Text("Choose File"),
              ),
              const SizedBox(height: 20),
              Text(
                result,
                textAlign: TextAlign.center,
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
