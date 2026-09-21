import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ===============================================================
/// SMIRITHI SAATHI — LUXURY ELDERLY-FIRST THEME & DESIGN TOKENS
/// ===============================================================
class AppTheme {
  AppTheme._();

  // Premium Botanical & Amber Palette
  static const Color forest = Color(0xFF0D5C46);
  static const Color deepForest = Color(0xFF073326);
  static const Color emerald = Color(0xFF148A65);
  static const Color sage = Color(0xFFD5E7DB);
  static const Color paleSage = Color(0xFFEEF6F1);
  static const Color cream = Color(0xFFF9F6EE);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color warmAmber = Color(0xFFE29B27);
  static const Color softGold = Color(0xFFFEF6E4);
  static const Color coral = Color(0xFFDD5A3D);
  static const Color paleCoral = Color(0xFFFDEBE6);
  static const Color lavender = Color(0xFFE9E3F5);
  static const Color sand = Color(0xFFF0E6D0);
  static const Color ink = Color(0xFF121C18);
  static const Color muted = Color(0xFF485951);
  static const Color terracotta = Color(0xFFB45A32);
  static const Color paleTerracotta = Color(0xFFF4E4D8);
  static const Color success = Color(0xFF1E7A4A);
  static const Color warning = Color(0xFFD98216);
  static const Color error = Color(0xFFBA3333);
  static const Color divider = Color(0xFFDCD5C8);
  static const Color navBar = Color(0xFFFFFFFF);

  // Spacing
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // Radii
  static const double radius12 = 12;
  static const double radius16 = 16;
  static const double radius18 = 18;
  static const double radius20 = 20;
  static const double radius24 = 24;
  static const double radius28 = 28;
  static const double radius32 = 32;

  static const double minTouchTarget = 58;
  static const double navHeight = 86;

  // Premium Gradients
  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF179E74), Color(0xFF0D5C46)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient deepHeroGradient = LinearGradient(
    colors: [Color(0xFF10604A), Color(0xFF062B20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF3B748), Color(0xFFD88918)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coralGradient = LinearGradient(
    colors: [Color(0xFFE86A50), Color(0xFFC74324)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF7F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: deepForest.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: deepForest.withValues(alpha: 0.11),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get emeraldGlow => [
        BoxShadow(
          color: forest.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get amberGlow => [
        BoxShadow(
          color: warmAmber.withValues(alpha: 0.30),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // Decorations
  static BoxDecoration get premiumCard => BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(radius24),
        border: Border.all(color: divider, width: 1.3),
        boxShadow: softShadow,
      );

  static BoxDecoration get softGreenCard => BoxDecoration(
        color: sage,
        borderRadius: BorderRadius.circular(radius24),
      );

  static BoxDecoration get warmCard => BoxDecoration(
        color: paleTerracotta,
        borderRadius: BorderRadius.circular(radius24),
      );

  // ThemeData
  static ThemeData get light {
    final nunito = GoogleFonts.nunitoTextTheme(_textTheme);

    const colorScheme = ColorScheme.light(
      primary: forest,
      onPrimary: Colors.white,
      secondary: warmAmber,
      onSecondary: Colors.white,
      surface: paper,
      onSurface: ink,
      error: error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: cream,
      visualDensity: VisualDensity.standard,
      textTheme: nunito,
      primaryTextTheme: nunito,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 25,
          fontWeight: FontWeight.w900,
          color: ink,
          height: 1.2,
        ),
        iconTheme: const IconThemeData(color: ink, size: 28),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          minimumSize: const Size(minTouchTarget, 60),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius20),
          ),
          elevation: 0,
          textStyle: GoogleFonts.nunito(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forest,
          minimumSize: const Size(minTouchTarget, 58),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: forest, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius20),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: forest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
        hintStyle: GoogleFonts.nunito(fontSize: 17, color: muted),
        labelStyle: GoogleFonts.nunito(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: muted,
        ),
        prefixIconColor: forest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius20),
          borderSide: const BorderSide(color: divider, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius20),
          borderSide: const BorderSide(color: divider, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius20),
          borderSide: const BorderSide(color: forest, width: 2.2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1.2,
        space: 1,
      ),
    );
  }

  static TextTheme get _textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          height: 1.15,
          color: ink,
        ),
        displaySmall: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          height: 1.18,
          color: ink,
        ),
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.22,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          height: 1.25,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          height: 1.3,
          color: ink,
        ),
        titleSmall: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          height: 1.3,
          color: ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.45,
          color: muted,
        ),
        bodySmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: muted,
        ),
      );
}
