import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme:
            ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        cardColor: Colors.white,
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0B0B0C),
        cardColor: const Color(0xFF1C1C1E),
      );
}
