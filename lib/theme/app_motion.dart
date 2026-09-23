import 'package:flutter/material.dart';

/// ===============================================================
/// SMRITI SAATHI — MOTION SYSTEM
/// Calm, elder-appropriate motion: slightly slower than typical apps,
/// with soft easing so nothing feels abrupt or jittery.
/// ===============================================================
class AppMotion {
  AppMotion._();

  // ── Duration tokens ──
  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration base = Duration(milliseconds: 340);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration slower = Duration(milliseconds: 640);

  // ── Curve tokens ──
  /// Gentle deceleration for entrances (content settling in).
  static const Curve entrance = Curves.easeOutCubic;

  /// Emphasized, slightly springy for tactile/selection feedback.
  static const Curve emphasized = Curves.easeOutBack;

  /// Smooth symmetric ease for state changes (color/size).
  static const Curve smooth = Curves.easeInOutCubic;

  /// Soft ease for breathing / looping ambient motion.
  static const Curve breathe = Curves.easeInOut;

  /// Staggered delay for the Nth item in a sequence.
  static Duration staggerDelay(int index, {int stepMs = 70, int maxMs = 500}) {
    final ms = (index * stepMs).clamp(0, maxMs);
    return Duration(milliseconds: ms);
  }
}

/// A gentle fade-through + subtle vertical slide page transition,
/// wired app-wide via [ThemeData.pageTransitionsTheme] so every
/// Navigator.push(MaterialPageRoute(...)) automatically feels premium.
class PremiumPageTransitionsBuilder extends PageTransitionsBuilder {
  const PremiumPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: AppMotion.entrance));

    final scale = Tween<double>(begin: 0.985, end: 1.0)
        .animate(CurvedAnimation(parent: animation, curve: AppMotion.entrance));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(scale: scale, child: child),
      ),
    );
  }
}
