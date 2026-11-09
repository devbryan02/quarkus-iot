import 'package:flutter/material.dart';

import 'features/startup/startup_screen.dart';

class KivoApp extends StatelessWidget {
  const KivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kivo',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const StartupScreen(),
    );
  }
}
