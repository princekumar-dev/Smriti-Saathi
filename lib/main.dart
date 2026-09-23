import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'navigation/app_shell.dart';
import 'screens/caretaker/caretaker_dashboard_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_assets.dart';
import 'services/local_model_manager.dart';
import 'state/app_settings.dart';
import 'state/auth_session.dart';
import 'state/auth_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await AppAssets.init();
  LocalModelManager().init();
  runApp(const SmirithiSaathiApp());
}

class SmirithiSaathiApp extends StatefulWidget {
  const SmirithiSaathiApp({super.key});

  @override
  State<SmirithiSaathiApp> createState() => _SmirithiSaathiAppState();
}

class _SmirithiSaathiAppState extends State<SmirithiSaathiApp> {
  final AppSettings _settings = AppSettings();
  final AuthState _auth = AuthState();
  final AuthSession _legacySession = AuthSession();
  bool _splashCompleted = false;

  @override
  void initState() {
    super.initState();
    _warmUpFonts();

    // On web, index.html already renders a fully-branded loading splash that
    // stays up until Flutter's first frame — so showing the Flutter splash too
    // would be a second, duplicate splash. Skip it there and hand straight to
    // the first real screen. On mobile there is no HTML splash, so keep the
    // branded Flutter splash and let its animation settle.
    if (kIsWeb) {
      _splashCompleted = true;
    } else {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) {
          setState(() => _splashCompleted = true);
        }
      });
    }
  }

  bool _assetsPrewarmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_assetsPrewarmed) {
      _assetsPrewarmed = true;
      _precacheCoreAssets();
    }
  }

  void _precacheCoreAssets() {
    PaintingBinding.instance.imageCache.maximumSize = 1000;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20;
    for (final path in const [
      'assets/images/logo.png',
      'assets/images/brand_lockup_trans.png',
      'assets/images/motto_banner_trans.png',
    ]) {
      precacheImage(AssetImage(path), context).catchError((_) {});
    }
  }

  void _warmUpFonts() {
    try {
      GoogleFonts.comfortaa();
      GoogleFonts.comfortaa(fontWeight: FontWeight.w700);
      GoogleFonts.plusJakartaSans();
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600);
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700);
      GoogleFonts.caveat(fontWeight: FontWeight.w600);
      GoogleFonts.caveat(fontWeight: FontWeight.w700);
      GoogleFonts.dmSans();
      GoogleFonts.dmSans(fontWeight: FontWeight.w600);
      GoogleFonts.dmSans(fontWeight: FontWeight.w700);
      GoogleFonts.playfairDisplay();
      GoogleFonts.outfit();
      GoogleFonts.nunito();
      GoogleFonts.pendingFonts();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: _settings,
      child: AuthScope(
        auth: _auth,
        child: AuthSessionScope(
          session: _legacySession,
          child: MaterialApp(
            title: 'Smriti Saathi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            builder: (context, child) {
              return ListenableBuilder(
                listenable: _settings,
                builder: (context, _) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(_settings.textScale),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              );
            },
            home: ListenableBuilder(
              listenable: Listenable.merge([_auth, _settings]),
              builder: (context, _) {
                final screen = _getInitialScreen();
                // Shared warm base so the two differently-tinted screens never
                // blend into a muddy flash mid-transition.
                return ColoredBox(
                  color: const Color(0xFFFDFBF4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 620),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    // Keep the incoming screen on top and both centered so the
                    // fade-through stacks cleanly without a layout jump.
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      // Fade-through: incoming fade is held back to the second
                      // half so it doesn't ghost over the outgoing splash,
                      // while a whisper of scale gives a premium "open" feel.
                      final fade = CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.30, 1.0,
                            curve: Curves.easeOut),
                        reverseCurve: const Interval(0.0, 0.70,
                            curve: Curves.easeIn),
                      );
                      final scale = Tween<double>(begin: 0.985, end: 1.0)
                          .animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ));
                      return FadeTransition(
                        opacity: fade,
                        child: ScaleTransition(
                          scale: scale,
                          filterQuality: FilterQuality.low,
                          child: child,
                        ),
                      );
                    },
                    child: screen,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _getInitialScreen() {
    if (!_auth.isInitialized || !_splashCompleted) {
      // On web the HTML splash (index.html) is still on top and fading out
      // here, so render a seamless warm frame underneath rather than the
      // Flutter splash — that avoids a second, misaligned splash flashing
      // through. On mobile, show the real branded splash.
      if (kIsWeb) {
        return const ColoredBox(
          color: Color(0xFFFDFBF4),
          key: ValueKey('screen_web_boot'),
        );
      }
      return const PremiumSplashScreen(key: ValueKey('screen_splash'));
    }

    if (!_settings.hasSelectedLanguage) {
      return const LanguageSelectionScreen(key: ValueKey('screen_language'));
    }

    if (_auth.isCaretaker) {
      return const CaretakerDashboardScreen(key: ValueKey('screen_caretaker'));
    } else if (_auth.isPatient) {
      return const AppShell(key: ValueKey('screen_patient'));
    } else {
      return const OnboardingScreen(key: ValueKey('screen_onboarding'));
    }
  }
}

/// Premium animated splash/loading screen with brand identity & falling leaves
class PremiumSplashScreen extends StatefulWidget {
  const PremiumSplashScreen({super.key});

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entrance; // Staggered content entrance
  late AnimationController _ripple;   // Expanding energy rings
  late AnimationController _breathe;  // Logo breathing & levitation
  late AnimationController _progress; // Indeterminate progress slider
  late AnimationController _leaf;     // Falling leaves & particles

  int _statusIndex = 0;
  Timer? _statusTimer;
  static const List<String> _statusMessages = [
    '🍃 Starting your companion…',
    '✨ Preparing your safe sanctuary…',
    '🌿 Gathering your precious memories…',
    '🛡️ 100% Private & on-device…',
    '🌸 Almost ready for you…',
  ];

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _ripple = AnimationController(
      duration: const Duration(milliseconds: 3600),
      vsync: this,
    )..repeat();

    _breathe = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _progress = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _leaf = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    // Staggered status message rotation (repeat() never fires `completed`,
    // so drive the cycle with a periodic timer instead).
    _statusTimer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (mounted) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statusMessages.length;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _entrance.dispose();
    _ripple.dispose();
    _breathe.dispose();
    _progress.dispose();
    _leaf.dispose();
    super.dispose();
  }

  /// Staggered fade + rise for content element [i].
  Widget _rise(int i, Widget child) {
    final start = (0.06 + i * 0.12).clamp(0.0, 0.7);
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, cachedChild) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 20),
          child: cachedChild,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.2,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFBF8F1),
                  Color(0xFFEEF5EA),
                  Color(0xFFE2EDE0),
                ],
                stops: [0.0, 0.38, 0.75, 1.0],
              ),
            ),
          ),

          // Custom animated falling leaves & golden embers
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _leaf,
              builder: (context, _) {
                return CustomPaint(
                  painter: _FallingLeavesPainter(progress: _leaf.value),
                );
              },
            ),
          ),

          // Main stage content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // Logo Stage with Ripple Rings & Breathing Levitation
                      _rise(
                        0,
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ripple ring 1
                              AnimatedBuilder(
                                animation: _ripple,
                                builder: (context, _) {
                                  final val = _ripple.value;
                                  final scale = 0.65 + val * 0.7;
                                  final opacity = (1.0 - val).clamp(0.0, 0.6);
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.forest
                                              .withValues(alpha: opacity * 0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Ripple ring 2 (delayed)
                              AnimatedBuilder(
                                animation: _ripple,
                                builder: (context, _) {
                                  final val = (_ripple.value + 0.5) % 1.0;
                                  final scale = 0.65 + val * 0.7;
                                  final opacity = (1.0 - val).clamp(0.0, 0.5);
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFD4A373)
                                              .withValues(alpha: opacity * 0.45),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Breathing Glassmorphic Logo Orb
                              AnimatedBuilder(
                                animation: _breathe,
                                builder: (context, child) {
                                  final breatheVal = _breathe.value;
                                  return Transform.translate(
                                    offset: Offset(0, -4 * breatheVal),
                                    child: Transform.scale(
                                      scale: 1.0 + 0.03 * breatheVal,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 108,
                                  height: 108,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      center: Alignment(-0.35, -0.35),
                                      radius: 0.9,
                                      colors: [
                                        Colors.white,
                                        Color(0xFFF5FAF3),
                                        Color(0xFFEAF3E7),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.deepForest
                                            .withValues(alpha: 0.22),
                                        blurRadius: 32,
                                        offset: const Offset(0, 14),
                                      ),
                                      BoxShadow(
                                        color: AppTheme.forest
                                            .withValues(alpha: 0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                      const BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 0,
                                        spreadRadius: 6,
                                      ),
                                      BoxShadow(
                                        color: AppTheme.forest
                                            .withValues(alpha: 0.2),
                                        blurRadius: 0,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: AppAssets.logo(
                                      fit: BoxFit.contain,
                                      fallbackSize: 44,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // App Title with luxury typography
                      _rise(
                        1,
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🌿', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'Smriti Saathi',
                              style: GoogleFonts.comfortaa(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.deepForest,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Transform.scale(
                              scaleX: -1,
                              child: const Text('🌿',
                                  style: TextStyle(fontSize: 18)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      _rise(
                        2,
                        Text(
                          'Your AI Saathi for Everyday Life & Memories',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.forest.withValues(alpha: 0.9),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Motto banner
                      _rise(
                        3,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.forest.withValues(alpha: 0.2),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.forest.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Because every memory matters…',
                            style: GoogleFonts.caveat(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepForest,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Indeterminate Glowing Progress Track
                      _rise(
                        4,
                        Column(
                          children: [
                            Container(
                              width: 240,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.forest.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 0.8,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedBuilder(
                                  animation: _progress,
                                  builder: (context, _) {
                                    return Align(
                                      alignment: Alignment(
                                        -1.4 + 2.8 * _progress.value,
                                        0,
                                      ),
                                      child: Container(
                                        width: 90,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppTheme.deepForest,
                                              AppTheme.forest,
                                              AppTheme.sage,
                                              Color(0xFFE9C46A),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.sage
                                                  .withValues(alpha: 0.8),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Status message
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _statusMessages[_statusIndex],
                                key: ValueKey<int>(_statusIndex),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.deepForest
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Reassurance Chips
                      _rise(
                        5,
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _SplashChip(icon: '🔒', label: '100% Private'),
                            _SplashChip(icon: '⚡', label: 'Offline-Ready'),
                            _SplashChip(icon: '🎙️', label: 'Voice First'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small luxury reassurance pill used on the splash screen.
class _SplashChip extends StatelessWidget {
  const _SplashChip({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.forest.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forest.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepForest,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that renders gentle, calm drifting leaves in a
/// curated forest-green and amber palette (#1B4332 / #2D6A4F / #52B788 / #D4A373).
class _FallingLeavesPainter extends CustomPainter {
  final double progress;

  _FallingLeavesPainter({required this.progress});

  // Pre-configured calm, gentle leaf models (11 leaves total)
  static final List<_LeafModel> _leaves = List.generate(11, (i) {
    const colors = [
      Color(0xFF2D6A4F), // Forest Green
      Color(0xFF1B4332), // Deep Forest
      Color(0xFF52B788), // Sage Green
      Color(0xFFD4A373), // Amber
    ];
    return _LeafModel(
      xRatio: ((i * 43) % 100) / 100.0,
      yOffsetRatio: ((i * 61) % 100) / 100.0,
      size: 13.0 + (i % 3) * 2.5,
      speed: 0.38 + (i % 3) * 0.15, // Very slow, calm descent
      swayAmp: 14.0 + (i % 3) * 8.0,
      swayFreq: 1.0 + (i % 3) * 0.5,
      driftX: ((i % 2 == 0 ? 1 : -1) * (0.04 + (i % 3) * 0.02)),
      color: colors[i % colors.length],
      opacity: 0.32 + (i % 3) * 0.10, // Soft, soothing translucency
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final leaf in _leaves) {
      // Calculate current y position with wrapping
      final totalY = size.height + 60;
      final currentY = ((progress * leaf.speed + leaf.yOffsetRatio) % 1.0) * totalY - 30;

      // Sway x offset with subtle organic drift direction
      final sway = leaf.swayAmp * (leaf.xRatio > 0.5 ? 1 : -1);
      final currentX = ((leaf.xRatio * size.width) +
          sway * (progress * leaf.swayFreq * 1.5) +
          (leaf.driftX * size.width * progress)) % size.width;

      paint.color = leaf.color.withValues(alpha: leaf.opacity);

      canvas.save();
      canvas.translate(currentX < 0 ? currentX + size.width : currentX, currentY);
      canvas.rotate(progress * 2.5 + leaf.yOffsetRatio * 6.28);

      // Draw graceful leaf shape (curved contour)
      final path = Path();
      final s = leaf.size;
      path.moveTo(0, -s);
      path.quadraticBezierTo(s * 0.55, -s * 0.15, 0, s);
      path.quadraticBezierTo(-s * 0.55, -s * 0.15, 0, -s);
      canvas.drawPath(path, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FallingLeavesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _LeafModel {
  final double xRatio;
  final double yOffsetRatio;
  final double size;
  final double speed;
  final double swayAmp;
  final double swayFreq;
  final double driftX;
  final Color color;
  final double opacity;

  const _LeafModel({
    required this.xRatio,
    required this.yOffsetRatio,
    required this.size,
    required this.speed,
    required this.swayAmp,
    required this.swayFreq,
    required this.driftX,
    required this.color,
    required this.opacity,
  });
}
