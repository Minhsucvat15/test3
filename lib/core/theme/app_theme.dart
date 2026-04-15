import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF090B10),
    primaryColor: const Color(0xFF1ED760),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1ED760),
      surface: Color(0xFF12141A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    useMaterial3: true,
  );
}