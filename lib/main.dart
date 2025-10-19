import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
    WidgetsFlutterBinding.ensureInitialized();
    //await Firebase.initializeApp();
    runApp(const MetronomeHubApp());
}

class MetronomeHubApp extends StatelessWidget {
  const MetronomeHubApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metronome Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        useMaterial3: true,
      ),
      home: const LandingScreen(),
    );
  }
}
