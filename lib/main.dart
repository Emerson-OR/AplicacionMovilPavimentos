import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const PavementAIApp());
}

class PavementAIApp extends StatelessWidget {
  const PavementAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PavementAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
      ),
      home: const HomePage(),
    );
  }
}
