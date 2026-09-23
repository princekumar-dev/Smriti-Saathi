import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_translations.dart';
import '../services/app_assets.dart';
import '../state/app_settings.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/language_selection_modal.dart';
import 'auth/caretaker_auth_screen.dart';

/// ===============================================================
/// ONBOARDING — Premium botanical, fully typographed experience
/// Cohesive with the natural growth-rings splash: drifting leaves,
/// breathing glass orb, ripple rings, and elegant typographic branding.
/// Built entirely with Flutter's built-in animation (offline-first).
/// ===============================================================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _ambient; // drifting leaves
  late final AnimationController _breathe; // orb levitation
  late final AnimationController _ripple; // expanding rings

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      duration: const Duration(seconds: 14),
      vsync: this,
    )..repeat();
    _breathe = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);
    _ripple = AnimationController(
      duration: const Duration(milliseconds: 3600),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo.png'), context).catchError((_) {});
  }

  @override
  void dispose() {
    _ambient.dispose();
    _breathe.dispose();
    _ripple.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _openLanguageSelector({bool isDismissible = true}) {
    LanguageSelectionModal.show(context, isDismissible: isDismissible);
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      _finishOnboarding();
    }
  }

  bool _isSkipping = false;

  /// Fast-forwards straight to the last page with a single, buttery-smooth transition.
  Future<void> _skipToLast(int totalPages) async {
    if (_isSkipping) return;
    _isSkipping = true;
    await _pageController.animateToPage(
      totalPages - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    );
    _isSkipping = false;
  }

  void _finishOnboarding() async {
    final auth = AuthScope.of(context);
    await auth.completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CaretakerAuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final translation = AppTranslations.get(settings.language);
    final currentLang = AppTranslations.getLanguageInfo(settings.language);

    final List<_OnboardingData> pages = [
      _OnboardingData(
        icon: Icons.favorite_rounded,
        label: translation.slides[0].label,
        title: translation.slides[0].title,
        motto: translation.slides[0].motto,
        description: translation.slides[0].description,
        accent: AppTheme.forest,
        soft: const Color(0xFFEAF3EC),
        isFlagshipBrand: true,
        mottoBannerText: translation.mottoBanner,
        chips: [
          (icon: Icons.mic_rounded, text: translation.slides[0].tags[0]),
          (icon: Icons.photo_library_rounded, text: translation.slides[0].tags[1]),
          (icon: Icons.lock_rounded, text: translation.slides[0].tags[2]),
        ],
      ),
      _OnboardingData(
        icon: Icons.mic_rounded,
        label: translation.slides[1].label,
        title: translation.slides[1].title,
        motto: translation.slides[1].motto,
        description: translation.slides[1].description,
        accent: AppTheme.warmAmber,
        soft: const Color(0xFFFBF1DC),
        isFlagshipBrand: false,
        mottoBannerText: translation.mottoBanner,
        chips: [
          (icon: Icons.translate_rounded, text: translation.slides[1].tags[0]),
          (icon: Icons.hearing_rounded, text: translation.slides[1].tags[1]),
          (icon: Icons.auto_awesome_rounded, text: translation.slides[1].tags[2]),
        ],
      ),
      _OnboardingData(
        icon: Icons.photo_album_rounded,
        label: translation.slides[2].label,
        title: translation.slides[2].title,
        motto: translation.slides[2].motto,
        description: translation.slides[2].description,
        accent: AppTheme.coral,
        soft: const Color(0xFFFBE7E0),
        isFlagshipBrand: false,
        mottoBannerText: translation.mottoBanner,
        chips: [
          (icon: Icons.face_rounded, text: translation.slides[2].tags[0]),
          (icon: Icons.record_voice_over_rounded, text: translation.slides[2].tags[1]),
          (icon: Icons.cake_rounded, text: translation.slides[2].tags[2]),
        ],
      ),
      _OnboardingData(
        icon: Icons.offline_bolt_rounded,
        label: translation.slides[3].label,
        title: translation.slides[3].title,
        motto: translation.slides[3].motto,
        description: translation.slides[3].description,
        accent: AppTheme.emerald,
        soft: const Color(0xFFE4F1EA),
        isFlagshipBrand: false,
        mottoBannerText: translation.mottoBanner,
        chips: [
          (icon: Icons.offline_bolt_rounded, text: translation.slides[3].tags[0]),
          (icon: Icons.security_rounded, text: translation.slides[3].tags[1]),
          (icon: Icons.handshake_rounded, text: translation.slides[3].tags[2]),
        ],
      ),
    ];

    final activeAccent = pages[_currentPage].accent;
    final activeSoft = pages[_currentPage].soft;
    final isLastPage = _currentPage == pages.length - 1;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Stack(
        children: [
          // Ambient botanical backdrop — isolated in RepaintBoundary for 60fps compositing
          Positioned.fill(
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.55),
                    radius: 1.25,
                    colors: [
                      Colors.white,
                      const Color(0xFFFBF8F1),
                      Color.lerp(const Color(0xFFEEF5EA),
                          activeSoft, 0.6)!,
                      Color.lerp(const Color(0xFFE2EDE0),
                          activeSoft, 0.5)!,
                    ],
                    stops: const [0.0, 0.4, 0.78, 1.0],
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _ambient,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _OnboardingLeavesPainter(
                        progress: _ambient.value,
                        accent: activeAccent,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(translation, settings, currentLang, pages.length),
                _buildProgressBar(pages.length, activeAccent),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const PageScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: pages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      return RepaintBoundary(
                        child: _OnboardingPage(
                          key: ValueKey('onboarding_page_$index'),
                          data: pages[index],
                          isSmallScreen: isSmallScreen,
                          isEnglish: settings.language == 'English',
                          language: settings.language,
                          breathe: _breathe,
                          ripple: _ripple,
                        ),
                      );
                    },
                  ),
                ),
                _buildDots(pages.length, activeAccent),
                _buildBottomActions(
                    translation, settings, pages.length, isLastPage, activeAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ── Top bar: typographed brand · language pill · skip ──
  Widget _buildTopBar(dynamic translation, dynamic settings, dynamic currentLang,
      int totalPages) {
    final isLastPage = _currentPage == totalPages - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                // Logo in a gradient-ringed glass badge with soft glow.
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(2.2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.emerald.withValues(alpha: 0.9),
                        AppTheme.forest.withValues(alpha: 0.85),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.forest.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: AppAssets.logo(
                      fit: BoxFit.contain,
                      fallbackSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                // Two-tone typographed wordmark + micro tagline
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: GoogleFonts.comfortaa(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Smriti ',
                              style: TextStyle(color: AppTheme.deepForest),
                            ),
                            TextSpan(
                              text: 'Saathi',
                              style: TextStyle(color: AppTheme.emerald),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 9,
                              color: AppTheme.warmAmber.withValues(alpha: 0.9)),
                          const SizedBox(width: 3),
                          Text(
                            'AI Companion',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppTheme.muted.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _pill(
            highlighted: true,
            onTap: () => _openLanguageSelector(isDismissible: true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: AppTheme.emeraldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.language_rounded,
                      size: 13, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Text(
                  currentLang.nativeName,
                  style: AppTranslations.getFont(
                    settings.language,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: AppTheme.deepForest,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: AppTheme.forest),
              ],
            ),
          ),
          const SizedBox(width: 7),
          // "Skip" fast-forwards through the remaining pages to the last
          // one. On the last page there's nothing to skip, so it hides.
          if (!isLastPage)
            _pill(
              onTap: () => _skipToLast(totalPages),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    translation.skipButton,
                    style: AppTranslations.getFont(
                      settings.language,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.fast_forward_rounded,
                      size: 14, color: AppTheme.muted),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill({
    required VoidCallback onTap,
    required Widget child,
    bool highlighted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: highlighted ? 9 : 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: highlighted
                  ? [
                      Colors.white,
                      AppTheme.sage.withValues(alpha: 0.55),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.92),
                      Colors.white.withValues(alpha: 0.82),
                    ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: highlighted
                  ? AppTheme.forest.withValues(alpha: 0.28)
                  : AppTheme.forest.withValues(alpha: 0.14),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.forest
                    .withValues(alpha: highlighted ? 0.14 : 0.06),
                blurRadius: highlighted ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ── Segmented progress bar with 60fps hardware animation ──
  Widget _buildProgressBar(int total, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
      child: Row(
        children: List.generate(total, (index) {
          final isCompleted = index < _currentPage;
          final isCurrent = index == _currentPage;
          final isActive = isCompleted || isCurrent;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 3.5,
                right: index == total - 1 ? 0 : 3.5,
              ),
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          accent,
                          Color.lerp(accent, AppTheme.deepForest, 0.35)!,
                        ],
                      )
                    : null,
                color: isActive
                    ? null
                    : AppTheme.divider.withValues(alpha: 0.5),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 1.5),
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Animated dots with 60fps hardware animation ──
  Widget _buildDots(int total, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (index) {
          final isSelected = _currentPage == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 7,
            width: isSelected ? 28 : 7,
            decoration: BoxDecoration(
              color: isSelected ? accent : AppTheme.divider,
              borderRadius: BorderRadius.circular(6),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
  // ── Bottom actions: back · continue/get-started · trust line ──
  Widget _buildBottomActions(dynamic translation, dynamic settings, int total,
      bool isLastPage, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentPage > 0) ...[
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.deepForest,
                        backgroundColor: Colors.white.withValues(alpha: 0.7),
                        side: BorderSide(
                          color: AppTheme.forest.withValues(alpha: 0.2),
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                        ),
                      ),
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.fastOutSlowIn,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 19),
                      label: Text(
                        translation.backButton,
                        style: AppTranslations.getFont(
                          settings.language,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: AnimatedScaleButton(
                    onTap: () => _nextPage(total),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent,
                            Color.lerp(accent, AppTheme.deepForest, 0.28)!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radius18),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.38),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage
                                ? translation.getStartedButton
                                : translation.continueButton,
                            style: AppTranslations.getFont(
                              settings.language,
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastPage
                                ? Icons.check_circle_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_rounded,
                  size: 13, color: AppTheme.muted.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  translation.footerTrust,
                  textAlign: TextAlign.center,
                  style: AppTranslations.getFont(
                    settings.language,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.muted.withValues(alpha: 0.8),
                    letterSpacing: 0.15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single onboarding page — hardware-isolated breathing hero orb with ripple
/// rings, typographed regional headline, handwritten motto, narrative body,
/// and glassy feature chips. Pure 60fps rendering without widget rebuilds.
class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final bool isSmallScreen;
  final bool isEnglish;
  final String language;
  final Animation<double> breathe;
  final Animation<double> ripple;

  const _OnboardingPage({
    super.key,
    required this.data,
    required this.isSmallScreen,
    required this.isEnglish,
    required this.language,
    required this.breathe,
    required this.ripple,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 6),
        child: Column(
          children: [
            _buildHeroVisual(),
            SizedBox(height: isSmallScreen ? 20 : 28),
            _buildTitle(),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildGlassStory(),
            SizedBox(height: isSmallScreen ? 18 : 24),
            _buildFeatureTags(),
            if (data.isFlagshipBrand) ...[
              SizedBox(height: isSmallScreen ? 16 : 20),
              _buildMottoBanner(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Breathing glass orb + dual ripple rings (isolated for 60fps) ──
  Widget _buildHeroVisual() {
    final orbSize = isSmallScreen ? 104.0 : 120.0;
    final ringSize = isSmallScreen ? 150.0 : 172.0;

    return RepaintBoundary(
      child: SizedBox(
        width: ringSize + 20,
        height: ringSize + 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: ripple,
              builder: (context, _) {
                final v = ripple.value;
                return Transform.scale(
                  scale: 0.62 + v * 0.7,
                  child: Container(
                    width: ringSize,
                    height: ringSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: data.accent
                            .withValues(alpha: (1.0 - v).clamp(0.0, 0.55) * 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: ripple,
              builder: (context, _) {
                final v = (ripple.value + 0.5) % 1.0;
                return Transform.scale(
                  scale: 0.62 + v * 0.7,
                  child: Container(
                    width: ringSize,
                    height: ringSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4A373)
                            .withValues(alpha: (1.0 - v).clamp(0.0, 0.5) * 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: ringSize * 0.82,
              height: ringSize * 0.82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.soft.withValues(alpha: 0.7),
              ),
            ),
            AnimatedBuilder(
              animation: breathe,
              builder: (context, child) {
                final b = breathe.value;
                return Transform.translate(
                  offset: Offset(0, -5 * b),
                  child: Transform.scale(scale: 1.0 + 0.03 * b, child: child),
                );
              },
              child: Container(
                width: orbSize,
                height: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.35, -0.35),
                    radius: 0.95,
                    colors: [Colors.white, Color(0xFFF6FAF4), Color(0xFFEDF4EA)],
                  ),
                  border: Border.all(
                    color: data.accent.withValues(alpha: 0.18),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.accent.withValues(alpha: 0.22),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: AppTheme.deepForest.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: data.isFlagshipBrand
                    ? Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                        child: AppAssets.logo(
                          fit: BoxFit.contain,
                          fallback: Icon(
                            data.icon,
                            size: isSmallScreen ? 40 : 46,
                            color: data.accent,
                          ),
                        ),
                      )
                    : Icon(
                        data.icon,
                        size: isSmallScreen ? 42 : 50,
                        color: data.accent,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      data.title,
      textAlign: TextAlign.center,
      style: AppTranslations.getFont(
        language,
        fontSize: isSmallScreen
            ? (data.isFlagshipBrand ? 33 : 27)
            : (data.isFlagshipBrand ? 38 : 30),
        fontWeight: FontWeight.w900,
        height: 1.12,
        color: AppTheme.deepForest,
        letterSpacing: -0.4,
      ),
    );
  }

  // ── Frosted-glass narrative card: hardware-accelerated, zero shader stall ──
  Widget _buildGlassStory() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: isSmallScreen ? 12 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: data.accent.withValues(alpha: 0.25),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: data.accent.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.deepForest.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        data.motto,
        textAlign: TextAlign.center,
        style: AppTranslations.getFont(
          language,
          fontSize: data.isFlagshipBrand ? 15.5 : 14.5,
          fontWeight: FontWeight.w800,
          color: Color.lerp(
              data.accent, AppTheme.deepForest, 0.15),
          letterSpacing: 0.1,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildMottoBanner() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.forest.withValues(alpha: 0.16),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.forest.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.mottoBannerText,
              style: isEnglish
                  ? GoogleFonts.caveat(
                      fontSize: isSmallScreen ? 20 : 23,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepForest,
                      letterSpacing: 0.2,
                    )
                  : AppTranslations.getFont(
                      language,
                      fontSize: isSmallScreen ? 14 : 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepForest,
                    ),
            ),
            const SizedBox(width: 7),
            Icon(Icons.favorite_rounded, size: 16, color: data.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: data.chips.map((chip) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: data.accent.withValues(alpha: 0.2),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepForest.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(chip.icon, size: 14, color: data.accent),
              const SizedBox(width: 6),
              Text(
                chip.text,
                style: AppTranslations.getFont(
                  language,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepForest,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String label;
  final String title;
  final String motto;
  final String description;
  final Color accent;
  final Color soft;
  final bool isFlagshipBrand;
  final String mottoBannerText;
  final List<({IconData icon, String text})> chips;

  const _OnboardingData({
    required this.icon,
    required this.label,
    required this.title,
    required this.motto,
    required this.description,
    required this.accent,
    required this.soft,
    required this.isFlagshipBrand,
    required this.mottoBannerText,
    required this.chips,
  });

  String get subtitle => motto;
}

/// Gentle drifting leaves behind the onboarding pages — mirrors the
/// splash's botanical motion, tinted subtly toward the active accent.
class _OnboardingLeavesPainter extends CustomPainter {
  final double progress;
  final Color accent;

  _OnboardingLeavesPainter({required this.progress, required this.accent});

  static final List<_Leaf> _leaves = List.generate(9, (i) {
    return _Leaf(
      xRatio: ((i * 47) % 100) / 100.0,
      yOffset: ((i * 67) % 100) / 100.0,
      size: 12.0 + (i % 3) * 3.0,
      speed: 0.32 + (i % 3) * 0.12,
      swayAmp: 12.0 + (i % 3) * 7.0,
      opacity: 0.12 + (i % 3) * 0.06,
      useAccent: i % 2 == 0,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const green = Color(0xFF52B788);

    for (final leaf in _leaves) {
      final totalY = size.height + 60;
      final y = ((progress * leaf.speed + leaf.yOffset) % 1.0) * totalY - 30;
      final sway = leaf.swayAmp * (leaf.xRatio > 0.5 ? 1 : -1);
      final x = ((leaf.xRatio * size.width) + sway * (progress * 1.5)) %
          size.width;

      paint.color =
          (leaf.useAccent ? accent : green).withValues(alpha: leaf.opacity);

      canvas.save();
      canvas.translate(x < 0 ? x + size.width : x, y);
      canvas.rotate(progress * 2.2 + leaf.yOffset * 6.28);
      final s = leaf.size;
      final path = Path()
        ..moveTo(0, -s)
        ..quadraticBezierTo(s * 0.55, -s * 0.15, 0, s)
        ..quadraticBezierTo(-s * 0.55, -s * 0.15, 0, -s);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingLeavesPainter old) =>
      old.progress != progress || old.accent != accent;
}

class _Leaf {
  final double xRatio;
  final double yOffset;
  final double size;
  final double speed;
  final double swayAmp;
  final double opacity;
  final bool useAccent;

  const _Leaf({
    required this.xRatio,
    required this.yOffset,
    required this.size,
    required this.speed,
    required this.swayAmp,
    required this.opacity,
    required this.useAccent,
  });
}
