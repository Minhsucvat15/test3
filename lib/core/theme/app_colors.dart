import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color brand = Color(0xFF1ED760);
  static const Color brandAlt = Color(0xFF0D8BFF);
  static const Color accent = Color(0xFFFF6B9D);

  // Dark
  static const Color bgDark = Color(0xFF090B10);
  static const Color bgDark2 = Color(0xFF10131A);
  static const Color bgDark3 = Color(0xFF1A1F2E);
  static const Color surfaceDark = Color(0xFF12141A);
  static const Color cardDark = Color(0xFF181B22);

  // Light
  static const Color bgLight = Color(0xFFF6F7FB);
  static const Color bgLight2 = Color(0xFFEEF1F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFAFBFD);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brand, brandAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFFC36B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
