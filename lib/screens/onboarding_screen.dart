import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_translations.dart';
import '../state/app_settings.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/language_selection_modal.dart';
import 'auth/caretaker_auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openLanguageSelector({bool isDismissible = true}) {
    LanguageSelectionModal.show(
      context,
      isDismissible: isDismissible,
    );
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
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
        accent: AppTheme.sage,
        badgeColor: AppTheme.forest,
        gradientColors: const [Color(0xFFEEF6F1), Color(0xFFD5E7DB)],
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
        accent: AppTheme.softGold,
        badgeColor: AppTheme.warmAmber,
        gradientColors: const [Color(0xFFFEF6E4), Color(0xFFF5E6C8)],
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
        accent: AppTheme.paleCoral,
        badgeColor: AppTheme.coral,
        gradientColors: const [Color(0xFFFDEBE6), Color(0xFFF4D4CC)],
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
        accent: AppTheme.paleSage,
        badgeColor: AppTheme.forest,
        gradientColors: const [Color(0xFFEEF6F1), Color(0xFFD5E7DB)],
        isFlagshipBrand: false,
        mottoBannerText: translation.mottoBanner,
        chips: [
          (icon: Icons.offline_bolt_rounded, text: translation.slides[3].tags[0]),
          (icon: Icons.security_rounded, text: translation.slides[3].tags[1]),
          (icon: Icons.handshake_rounded, text: translation.slides[3].tags[2]),
        ],
      ),
    ];

    final isLastPage = _currentPage == pages.length - 1;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar with Brand + Language Pill + Skip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  // Brand Logo & Name
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          padding: const EdgeInsets.all(4.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.forest.withValues(alpha: 0.14),
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.forest.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Smriti Saathi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF184E77),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Language Switcher Pill
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openLanguageSelector(isDismissible: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF184E77).withValues(alpha: 0.16),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF184E77).withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentLang.flag,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentLang.nativeName,
                              style: AppTranslations.getFont(
                                settings.language,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: const Color(0xFF184E77),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: Color(0xFF184E77),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Skip Button Pill
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _finishOnboarding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF184E77).withValues(alpha: 0.14),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF184E77).withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              translation.skipButton,
                              style: AppTranslations.getFont(
                                settings.language,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: const Color(0xFF184E77),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: Color(0xFF184E77),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Segmented Progress Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: List.generate(pages.length, (index) {
                  final isCompleted = index < _currentPage;
                  final isCurrent = index == _currentPage;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 3.5,
                        right: index == pages.length - 1 ? 0 : 3.5,
                      ),
                      height: 4.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: isCurrent ? AppTheme.emeraldGradient : null,
                        color: isCompleted
                            ? AppTheme.forest
                            : isCurrent
                                ? null
                                : AppTheme.divider.withValues(alpha: 0.6),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color:
                                      AppTheme.forest.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1.5),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Carousel Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    data: pages[index],
                    isSmallScreen: isSmallScreen,
                    isEnglish: settings.language == 'English',
                    language: settings.language,
                  );
                },
              ),
            ),

            // Animated Dot Indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (index) {
                  final isSelected = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 7,
                    width: isSelected ? 30 : 7,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.emeraldGradient : null,
                      color: isSelected ? null : AppTheme.divider,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    AppTheme.forest.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

            // Bottom Actions (Back & Continue / Get Started)
            Padding(
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
                                side: BorderSide(
                                  color:
                                      AppTheme.forest.withValues(alpha: 0.2),
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radius18),
                                ),
                              ),
                              onPressed: () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded,
                                  size: 19),
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
                            onTap: () => _nextPage(pages.length),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.emeraldGradient,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radius18),
                                boxShadow: AppTheme.buttonGlow,
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
                  Text(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final bool isSmallScreen;
  final bool isEnglish;
  final String language;

  const _OnboardingPage({
    required this.data,
    this.isSmallScreen = false,
    this.isEnglish = true,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
        child: Column(
          children: [
            // Layered concentric luxury hero visual
            _buildHeroVisual(),
            SizedBox(height: isSmallScreen ? 14 : 18),

            // Category Label Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: data.accent.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: data.badgeColor.withValues(alpha: 0.18),
                  width: 1.1,
                ),
              ),
              child: Text(
                data.label,
                style: AppTranslations.getFont(
                  language,
                  fontSize: 11.5,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forest,
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),

            // Hero Headline with Dedicated Regional Script Typography
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: AppTranslations.getFont(
                language,
                fontSize: isSmallScreen
                    ? (data.isFlagshipBrand ? 32 : 25)
                    : (data.isFlagshipBrand ? 36 : 28),
                fontWeight: FontWeight.w900,
                height: 1.15,
                color: const Color(0xFF184E77),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: isSmallScreen ? 5 : 7),

            // Subtitle
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: AppTranslations.getFont(
                language,
                fontSize: data.isFlagshipBrand ? 15 : 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.forest,
                letterSpacing: 0.15,
                height: 1.3,
              ),
            ),
            SizedBox(height: isSmallScreen ? 10 : 14),

            // Authentic Motto Banner
            _buildMottoBanner(),
            SizedBox(height: isSmallScreen ? 10 : 14),

            // Narrative Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: AppTranslations.getFont(
                  language,
                  color: AppTheme.muted,
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w500,
                  height: 1.48,
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Feature Highlights Chips
            _buildFeatureTags(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroVisual() {
    final haloSize = isSmallScreen ? 144.0 : 164.0;
    final middleSize = isSmallScreen ? 116.0 : 132.0;
    final badgeSize = isSmallScreen ? 88.0 : 100.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer soft ambient ring
        Container(
          width: haloSize,
          height: haloSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: data.accent.withValues(alpha: 0.35),
          ),
        ),
        // Middle glowing ring
        Container(
          width: middleSize,
          height: middleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                data.accent.withValues(alpha: 0.7),
                data.badgeColor.withValues(alpha: 0.15),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: data.badgeColor.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
        // Inner elevated white card badge
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: data.badgeColor.withValues(alpha: 0.18),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepForest.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: data.isFlagshipBrand
              ? Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      data.icon,
                      size: isSmallScreen ? 38 : 44,
                      color: AppTheme.forest,
                    ),
                  ),
                )
              : Icon(
                  data.icon,
                  size: isSmallScreen ? 40 : 48,
                  color: data.badgeColor,
                ),
        ),
      ],
    );
  }

  Widget _buildMottoBanner() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF184E77).withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF184E77).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              data.mottoBannerText,
              style: isEnglish
                  ? GoogleFonts.caveat(
                      fontSize: isSmallScreen ? 18 : 21,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF184E77),
                      letterSpacing: 0.2,
                    )
                  : AppTranslations.getFont(
                      language,
                      fontSize: isSmallScreen ? 14 : 15.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF184E77),
                      letterSpacing: 0.1,
                    ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.favorite_border_rounded,
              size: 18,
              color: Color(0xFF184E77),
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: data.badgeColor.withValues(alpha: 0.16),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepForest.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                chip.icon,
                size: 14,
                color: data.badgeColor,
              ),
              const SizedBox(width: 5.5),
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
  final Color badgeColor;
  final List<Color> gradientColors;
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
    required this.badgeColor,
    required this.gradientColors,
    required this.isFlagshipBrand,
    required this.mottoBannerText,
    required this.chips,
  });

  String get subtitle => motto;
}
