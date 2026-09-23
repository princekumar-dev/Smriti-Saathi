import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'navigation/app_shell.dart';
import 'screens/caretaker/caretaker_dashboard_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/local_model_manager.dart';
import 'state/app_settings.dart';
import 'state/auth_session.dart';
import 'state/auth_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
              builder: (context, _) => _getInitialScreen(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getInitialScreen() {
    if (!_auth.isInitialized) {
      return const PremiumSplashScreen();
    }

    if (!_settings.hasSelectedLanguage) {
      return const LanguageSelectionScreen();
    }

    if (_auth.isCaretaker) {
      return const CaretakerDashboardScreen();
    } else if (_auth.isPatient) {
      return const AppShell();
    } else {
      return const OnboardingScreen();
    }
  }
}

/// Premium animated splash/loading screen with brand identity
class PremiumSplashScreen extends StatefulWidget {
  const PremiumSplashScreen({super.key});

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _glowController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressWidth;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    // Logo entrance animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Text entrance animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Progress bar animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _progressWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Glow pulse animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowOpacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textController.forward();
    _progressController.forward();
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9F6EE), Color(0xFFEEF6F1), Color(0xFFF9F6EE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Logo with glow
              AnimatedBuilder(
                animation: Listenable.merge([_logoController, _glowController]),
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.forest
                                      .withValues(alpha: _glowOpacity.value * 0.12),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // Middle ring
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.sage.withValues(alpha: 0.5),
                            ),
                          ),
                          // Inner logo circle
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.forest.withValues(alpha: 0.1),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color:
                                    AppTheme.forest.withValues(alpha: 0.12),
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.favorite_rounded,
                                  color: AppTheme.forest,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // App name
              FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(
                    children: [
                      Text(
                        'Smriti Saathi',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepForest,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your AI Saathi for Everyday Life',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.muted.withValues(alpha: 0.8),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Premium progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: AnimatedBuilder(
                  animation: _progressWidth,
                  builder: (context, child) {
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  // Track
                                  Container(
                                    height: 3.5,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppTheme.divider
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  // Fill
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 80),
                                    height: 3.5,
                                    width: constraints.maxWidth *
                                        _progressWidth.value,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.emeraldGradient,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.forest
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Preparing your companion...',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                AppTheme.muted.withValues(alpha: 0.6),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
