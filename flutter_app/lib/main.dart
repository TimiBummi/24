import 'package:flutter/material.dart';

import 'screens/camera_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TwentyFourSolverApp());
}

class TwentyFourSolverApp extends StatelessWidget {
  const TwentyFourSolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '24 Solver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const CameraScreen(),
    );
  }
}
