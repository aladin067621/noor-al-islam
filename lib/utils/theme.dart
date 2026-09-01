import 'package:flutter/material.dart';

/// ثيم التطبيق — وضع نهاري ووضع ليلي بطابع إسلامي هادئ
class AppTheme {
  // ألوان الهوية
  static const Color primaryGreen = Color(0xFF1B6B5A);
  static const Color darkGreen = Color(0xFF0F4A3E);
  static const Color gold = Color(0xFFB8860B);
  static const Color lightGold = Color(0xFFD4AF37);
  static const Color cream = Color(0xFFF7F4EC);

  static const String fontFamily = 'NotoNaskhArabic';
  static const String quranFontFamily = 'Amiri';

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: gold,
        surface: cream,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: gold,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      textTheme: _textTheme(Colors.black87),
      dividerColor: gold.withOpacity(0.3),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: lightGold,
        secondary: lightGold,
        surface: Color(0xFF15201C),
        onPrimary: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFF0E1714),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: lightGold,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF15201C),
      ),
      textTheme: _textTheme(Colors.white.withOpacity(0.92)),
      dividerColor: lightGold.withOpacity(0.3),
    );
  }

  static TextTheme _textTheme(Color color) {
    return TextTheme(
      bodyLarge: TextStyle(fontFamily: fontFamily, color: color, height: 1.8),
      bodyMedium: TextStyle(fontFamily: fontFamily, color: color, height: 1.8),
      titleLarge: TextStyle(fontFamily: fontFamily, color: color, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontFamily: fontFamily, color: color, fontWeight: FontWeight.bold),
    );
  }
}
