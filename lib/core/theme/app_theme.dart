import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bgDark,
    primaryColor: AppColors.brand,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.brand,
      secondary: AppColors.brandAlt,
      surface: AppColors.surfaceDark,
      onPrimary: Colors.black,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.cardDark,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bgLight,
    primaryColor: AppColors.brand,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.light(
      primary: AppColors.brand,
      secondary: AppColors.brandAlt,
      surface: AppColors.surfaceLight,
      onPrimary: Colors.white,
      onSurface: Color(0xFF15171C),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
      ),
    ),
  );
}

/// Helper resolve màu theo theme — gọi `AppPalette.of(context)` ở mọi widget.
class AppPalette {
  final Color bg;
  final Color bg2;
  final Color bg3;
  final Color card;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color border;
  final Color subtleFill;
  final List<Color> backgroundGradient;

  const AppPalette._({
    required this.bg,
    required this.bg2,
    required this.bg3,
    required this.card,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.border,
    required this.subtleFill,
    required this.backgroundGradient,
  });

  static AppPalette of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return const AppPalette._(
        bg: AppColors.bgDark,
        bg2: AppColors.bgDark2,
        bg3: AppColors.bgDark3,
        card: AppColors.cardDark,
        text: Colors.white,
        textMuted: Color(0xB3FFFFFF),
        textFaint: Color(0x80FFFFFF),
        border: Color(0x1FFFFFFF),
        subtleFill: Color(0x14FFFFFF),
        backgroundGradient: [
          AppColors.bgDark3,
          AppColors.bgDark2,
          AppColors.bgDark,
        ],
      );
    }
    return const AppPalette._(
      bg: AppColors.bgLight,
      bg2: AppColors.bgLight2,
      bg3: Color(0xFFE3E8F1),
      card: AppColors.cardLight,
      text: Color(0xFF15171C),
      textMuted: Color(0xCC15171C),
      textFaint: Color(0x9915171C),
      border: Color(0x1A15171C),
      subtleFill: Color(0x0F15171C),
      backgroundGradient: [
        Color(0xFFEAF1FB),
        Color(0xFFF6F7FB),
        Color(0xFFFFFFFF),
      ],
    );
  }
}
