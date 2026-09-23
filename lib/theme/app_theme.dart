import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_motion.dart';

/// ===============================================================
/// SMIRITHI SAATHI — PREMIUM ELDERLY-FIRST DESIGN SYSTEM
/// Typography: Playfair Display (brand) + DM Sans (body) + Nunito (elder)
/// ===============================================================
class AppTheme {
  AppTheme._();

  // ── Premium Botanical & Amber Palette ──
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

  // ── Spacing Tokens ──
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space18 = 18;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
  static const double space36 = 36;
  static const double space40 = 40;

  // ── Border Radii ──
  static const double radius10 = 10;
  static const double radius12 = 12;
  static const double radius14 = 14;
  static const double radius16 = 16;
  static const double radius18 = 18;
  static const double radius20 = 20;
  static const double radius24 = 24;
  static const double radius28 = 28;
  static const double radius32 = 32;
  static const double radius36 = 36;
  static const double radiusFull = 999;

  static const double minTouchTarget = 58;
  static const double navHeight = 86;

  // ── Premium Gradients ──
  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF179E74), Color(0xFF0D5C46)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldSoftGradient = LinearGradient(
    colors: [Color(0xFF1AAE80), Color(0xFF0E6B50)],
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

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF0D5C46), Color(0xFF148A65), Color(0xFF1AAE80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmHeroGradient = LinearGradient(
    colors: [Color(0xFFF9F6EE), Color(0xFFF0E6D0), Color(0xFFFDEBE6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient blueHeroGradient = LinearGradient(
    colors: [Color(0xFF184E77), Color(0xFF2D6A4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Premium Shadows ──
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

  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: forest.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: forest.withValues(alpha: 0.04),
          blurRadius: 48,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> get cardLift => [
        BoxShadow(
          color: deepForest.withValues(alpha: 0.07),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: deepForest.withValues(alpha: 0.03),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get buttonGlow => [
        BoxShadow(
          color: forest.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: forest.withValues(alpha: 0.15),
          blurRadius: 40,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get inputFocusShadow => [
        BoxShadow(
          color: forest.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Premium Decorations ──
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

  static BoxDecoration get glassCard => BoxDecoration(
        color: paper.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(radius24),
        border: Border.all(
          color: forest.withValues(alpha: 0.1),
          width: 1.2,
        ),
        boxShadow: premiumShadow,
      );

  static BoxDecoration get luxuryInputDecoration => BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(radius16),
        border: Border.all(color: divider.withValues(alpha: 0.8), width: 1.2),
      );

  // ── Premium Typography ──

  /// Brand / Display headings - Playfair Display (elegant serif)
  static TextStyle brandHeading({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
    Color color = deepForest,
    double height = 1.15,
    double letterSpacing = -0.3,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Section headings - DM Sans (clean geometric)
  static TextStyle sectionHeading({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w700,
    Color color = deepForest,
    double height = 1.25,
    double letterSpacing = -0.2,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Body text - DM Sans
  static TextStyle body({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
    Color color = muted,
    double height = 1.5,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// Label / small text - DM Sans
  static TextStyle label({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    Color color = muted,
    double height = 1.3,
    double letterSpacing = 0.3,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Elder-friendly text - Nunito (warm, rounded)
  static TextStyle elder({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w700,
    Color color = deepForest,
    double height = 1.4,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// Button text - DM Sans
  static TextStyle buttonText({
    double fontSize = 17,
    FontWeight fontWeight = FontWeight.w700,
    Color color = paper,
    double letterSpacing = 0.2,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Input text - DM Sans
  static TextStyle inputText({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
    Color color = deepForest,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Input hint - DM Sans
  static TextStyle inputHint({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? muted.withValues(alpha: 0.6),
    );
  }

  /// Caption / meta - DM Sans
  static TextStyle caption({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = 0.4,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? muted.withValues(alpha: 0.7),
      letterSpacing: letterSpacing,
    );
  }

  // ── ThemeData ──
  static ThemeData get light {
    final dmSansBase = GoogleFonts.dmSansTextTheme(_textTheme);

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
      textTheme: dmSansBase,
      primaryTextTheme: dmSansBase,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.2,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: ink, size: 26),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          minimumSize: const Size(minTouchTarget, 60),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius18),
          ),
          elevation: 0,
          textStyle: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forest,
          minimumSize: const Size(minTouchTarget, 58),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: forest, width: 1.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius18),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: forest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cream,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: muted.withValues(alpha: 0.55),
        ),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: muted,
        ),
        prefixIconColor: forest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: BorderSide(color: divider.withValues(alpha: 0.8), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: BorderSide(color: divider.withValues(alpha: 0.8), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: const BorderSide(color: forest, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: const BorderSide(color: error, width: 1.4),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1.2,
        space: 1,
      ),
      // Premium, calm page transitions applied to every MaterialPageRoute.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PremiumPageTransitionsBuilder(),
          TargetPlatform.iOS: PremiumPageTransitionsBuilder(),
          TargetPlatform.windows: PremiumPageTransitionsBuilder(),
          TargetPlatform.macOS: PremiumPageTransitionsBuilder(),
          TargetPlatform.linux: PremiumPageTransitionsBuilder(),
          TargetPlatform.fuchsia: PremiumPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: deepForest,
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius16),
        ),
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  static TextTheme get _textTheme => TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: ink,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          height: 1.12,
          color: ink,
          letterSpacing: -0.4,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.15,
          color: ink,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: ink,
          letterSpacing: -0.2,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: ink,
          letterSpacing: -0.1,
        ),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          height: 1.28,
          color: ink,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: ink,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.35,
          color: ink,
        ),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.35,
          color: ink,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: ink,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: muted,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: muted,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: ink,
          letterSpacing: 0.2,
        ),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: muted,
          letterSpacing: 0.3,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: muted,
          letterSpacing: 0.6,
        ),
      );
}
