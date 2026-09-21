import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import 'auth/caretaker_auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.favorite_rounded,
      label: 'YOUR AI COMPANION',
      title: 'Smriti Saathi',
      motto: 'Your AI Saathi for Everyday Life & Memories',
      description:
          'A patient, loving companion that listens with warmth, preserves your precious memories, and keeps you close to the people and stories that matter most.',
      accent: AppTheme.sage,
      badgeColor: AppTheme.forest,
    ),
    _OnboardingData(
      icon: Icons.mic_rounded,
      label: 'VOICE FIRST',
      title: 'Just Talk.\nSaathi Listens.',
      motto: 'Speak naturally, in your comfortable language',
      description:
          'Tap the large microphone and speak freely. Saathi listens with infinite patience, warmth, and care — never rushing you.',
      accent: AppTheme.softGold,
      badgeColor: AppTheme.warmAmber,
    ),
    _OnboardingData(
      icon: Icons.photo_album_rounded,
      label: 'CHERISHED MEMORIES',
      title: 'Keep Memories\nSafe & Close',
      motto: 'Preserving precious family heritage & smiles',
      description:
          'Preserve family photos, voice stories, familiar faces, and special dates in a calm, joyful sanctuary.',
      accent: AppTheme.paleCoral,
      badgeColor: AppTheme.coral,
    ),
    _OnboardingData(
      icon: Icons.offline_bolt_rounded,
      label: 'ALWAYS AVAILABLE',
      title: 'Always With You,\nEven Offline',
      motto: 'Works reliably anytime, anywhere',
      description:
          'All your core features work completely offline without internet. Your personal memories and routines stay 100% safe and private.',
      accent: AppTheme.paleSage,
      badgeColor: AppTheme.forest,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
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
    final isLastPage = _currentPage == _pages.length - 1;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Unified Luxury Top Navigation Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  // Left: Circular Logo Badge + Comfortaa Brand Name (Flex-safe)
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          padding: const EdgeInsets.all(5.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF184E77).withValues(alpha: 0.16),
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF184E77).withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Smriti Saathi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.comfortaa(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF184E77),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right: Refined Modern Skip Glass Pill
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _finishOnboarding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
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
                              'Skip',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF184E77),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
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

            // Segmented Stories-Style Stepper Progress Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: List.generate(_pages.length, (index) {
                  final isCompleted = index < _currentPage;
                  final isCurrent = index == _currentPage;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 3.5,
                        right: index == _pages.length - 1 ? 0 : 3.5,
                      ),
                      height: 4.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: isCurrent
                            ? const LinearGradient(
                                colors: [Color(0xFF184E77), Color(0xFF2D6A4F)],
                              )
                            : null,
                        color: isCompleted
                            ? const Color(0xFF2D6A4F)
                            : isCurrent
                                ? null
                                : AppTheme.divider.withValues(alpha: 0.6),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2D6A4F)
                                      .withValues(alpha: 0.35),
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

            // Main Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    data: _pages[index],
                    isSmallScreen: isSmallScreen,
                  );
                },
              ),
            ),

            // Expanding Animated Dot Indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isSelected = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 7,
                    width: isSelected ? 28 : 7,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.forest
                          : AppTheme.divider,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),

            // Bottom Actions
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
                                  color: AppTheme.forest.withValues(alpha: 0.2),
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radius18),
                                ),
                              ),
                              onPressed: () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded, size: 19),
                              label: Text(
                                'Back',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
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
                            onTap: _nextPage,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.emeraldGradient,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radius18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.forest.withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLastPage ? 'Get Started' : 'Continue',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
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
                    'Simple to use  •  Made with care  •  100% Private',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted.withValues(alpha: 0.75),
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

  const _OnboardingPage({
    required this.data,
    this.isSmallScreen = false,
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
                  color: data.badgeColor.withValues(alpha: 0.2),
                  width: 1.1,
                ),
              ),
              child: Text(
                data.label,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.forest,
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),

            // Hero Headline with Premium Typography
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: data.isFlagshipBrand
                  ? GoogleFonts.comfortaa(
                      fontSize: isSmallScreen ? 34 : 38,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: const Color(0xFF184E77),
                      letterSpacing: -0.4,
                    )
                  : GoogleFonts.outfit(
                      fontSize: isSmallScreen ? 27 : 30,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                      color: AppTheme.deepForest,
                      letterSpacing: -0.5,
                    ),
            ),
            SizedBox(height: isSmallScreen ? 5 : 7),

            // Subtitle
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: data.isFlagshipBrand ? 15.5 : 14.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.forest,
                letterSpacing: 0.15,
                height: 1.3,
              ),
            ),
            SizedBox(height: isSmallScreen ? 10 : 14),

            // Authentic Handwritten Motto Banner Artwork
            _buildMottoBanner(),
            SizedBox(height: isSmallScreen ? 10 : 14),

            // Narrative Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: AppTheme.muted,
                  fontSize: isSmallScreen ? 14.5 : 15.5,
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
              'Because every memory matters...',
              style: GoogleFonts.caveat(
                fontSize: isSmallScreen ? 18 : 21,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF184E77),
                letterSpacing: 0.2,
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
      children: data.chipItems.map((chip) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: data.badgeColor.withValues(alpha: 0.16),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepForest.withValues(alpha: 0.035),
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
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
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

  const _OnboardingData({
    required this.icon,
    required this.label,
    required this.title,
    required this.motto,
    required this.description,
    required this.accent,
    required this.badgeColor,
  });

  bool get isFlagshipBrand => title.contains('Smriti') || label.contains('COMPANION');
  String get subtitle => motto;

  List<({IconData icon, String text})> get chipItems {
    if (isFlagshipBrand) {
      return const [
        (icon: Icons.mic_rounded, text: 'Voice-First'),
        (icon: Icons.photo_library_rounded, text: 'Cherished Memories'),
        (icon: Icons.lock_rounded, text: '100% Private'),
      ];
    } else if (label.contains('VOICE')) {
      return const [
        (icon: Icons.translate_rounded, text: 'Speaks Your Language'),
        (icon: Icons.hearing_rounded, text: 'Calm & Patient'),
        (icon: Icons.auto_awesome_rounded, text: 'Zero Complex Menus'),
      ];
    } else if (label.contains('MEMORIES')) {
      return const [
        (icon: Icons.face_rounded, text: 'Family Faces'),
        (icon: Icons.record_voice_over_rounded, text: 'Voice Stories'),
        (icon: Icons.cake_rounded, text: 'Special Dates'),
      ];
    } else {
      return const [
        (icon: Icons.offline_bolt_rounded, text: 'Works Offline'),
        (icon: Icons.security_rounded, text: 'Zero Tracking'),
        (icon: Icons.handshake_rounded, text: 'Caregiver Connected'),
      ];
    }
  }

  List<String> get tags => chipItems.map((e) => e.text).toList();
}
