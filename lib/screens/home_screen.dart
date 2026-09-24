import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_translations.dart';
import '../navigation/app_shell.dart';
import '../services/memory_service.dart';
import '../state/app_settings.dart';
import '../state/auth_session.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../theme/app_motion.dart';
import '../widgets/fx/fade_slide_in.dart';
import '../widgets/language_selection_modal.dart';
import '../widgets/offline_badge.dart';
import '../widgets/section_title.dart';
import 'activities_screen.dart';
import 'memories_screen.dart';
import 'memory_garden_screen.dart';
import 'photo_memory_screen.dart';
import 'onboarding_screen.dart';
import 'routine_screen.dart';
import 'saathi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMood = 'Peaceful';

  String _getGreeting(HomeTranslation home) {
    final hour = DateTime.now().hour;
    if (hour < 12) return home.greetingMorning;
    if (hour < 17) return home.greetingAfternoon;
    return home.greetingEvening;
  }

  String _getUserName(BuildContext context) {
    try {
      final auth = AuthScope.of(context);
      if (auth.activePatient != null && auth.activePatient!.nickname.isNotEmpty) {
        return auth.activePatient!.nickname;
      }
      if (auth.activePatient != null && auth.activePatient!.name.isNotEmpty) {
        return auth.activePatient!.name;
      }
    } catch (_) {}

    try {
      final legacy = AuthSessionScope.of(context);
      if (legacy.activePatient != null && legacy.activePatient!.name.isNotEmpty) {
        return legacy.activePatient!.name;
      }
      if (legacy.displayName.isNotEmpty) {
        return legacy.displayName;
      }
    } catch (_) {}

    return '';
  }

  void _confirmLogout(BuildContext context) {
    final auth = AuthScope.of(context);
    final nav = Navigator.of(context);
    AuthSession? legacy;
    try {
      legacy = AuthSessionScope.of(context);
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.coral, size: 26),
            SizedBox(width: 10),
            Text('Testing: Log Out?'),
          ],
        ),
        content: const Text(
          'Do you want to exit Senior Companion mode and return to the onboarding screen?',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.coral,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              legacy?.logOut();

              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName(context);
    final settings = AppSettingsScope.of(context);
    final home = AppTranslations.getHome(settings.language);
    final currentLang = AppTranslations.getLanguageInfo(settings.language);

    final moods = [
      (label: home.happy, icon: Icons.sentiment_very_satisfied_rounded, color: AppTheme.warmAmber),
      (label: home.peaceful, icon: Icons.spa_rounded, color: AppTheme.emerald),
      (label: home.thoughtful, icon: Icons.menu_book_rounded, color: AppTheme.coral),
      (label: home.resting, icon: Icons.bedtime_rounded, color: const Color(0xFF7A68A6)),
    ];

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.goldGradient,
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.paper,
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppTheme.coral,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.isNotEmpty
                                ? '${_getGreeting(home)}, $userName'
                                : _getGreeting(home),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTranslations.getFont(
                              settings.language,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.deepForest,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            home.saathiReady,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTranslations.getFont(
                              settings.language,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Language Switcher Button
                    AnimatedScaleButton(
                      onTap: () => LanguageSelectionModal.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.paper,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.softShadow,
                          border: Border.all(color: AppTheme.forest.withValues(alpha: 0.2), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currentLang.flag, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              currentLang.id,
                              style: AppTranslations.getFont(
                                settings.language,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.forest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const OfflineBadge(compact: true),
                    const SizedBox(width: 6),
                    AnimatedScaleButton(
                      onTap: () => openSettings(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.paper,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.softShadow,
                          border: Border.all(color: AppTheme.divider, width: 1.2),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: AppTheme.forest,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Testing Logout Button
                    AnimatedScaleButton(
                      onTap: () => _confirmLogout(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.paleCoral,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.softShadow,
                          border: Border.all(color: AppTheme.coral.withValues(alpha: 0.4), width: 1.2),
                        ),
                        child: const Tooltip(
                          message: 'Log out / Switch account (Test Mode)',
                          child: Icon(
                            Icons.logout_rounded,
                            color: AppTheme.coral,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hero Breathing Voice Saathi Card
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: AppMotion.staggerDelay(1),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: _buildTalkToSaathiCard(context),
                ),
              ),
            ),

            // Mood Tracker Section
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: AppMotion.staggerDelay(2),
                child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      home.feelingQuestion,
                      style: AppTranslations.getFont(
                        settings.language,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: moods.map((m) {
                        final isSelected = _selectedMood == m.label;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedScaleButton(
                              onTap: () {
                                setState(() => _selectedMood = m.label);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${m.label}. ${home.saathiReady}.'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? m.color.withValues(alpha: 0.15) : AppTheme.paper,
                                  borderRadius: BorderRadius.circular(AppTheme.radius18),
                                  border: Border.all(
                                    color: isSelected ? m.color : AppTheme.divider,
                                    width: isSelected ? 2.0 : 1.2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: m.color.withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : AppTheme.softShadow,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      m.icon,
                                      color: isSelected ? m.color : AppTheme.muted,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      m.label,
                                      style: AppTranslations.getFont(
                                        settings.language,
                                        fontSize: 12.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? AppTheme.deepForest : AppTheme.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                ),
              ),
            ),

            // Daily Routine Preview Section
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: AppMotion.staggerDelay(3),
                child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
                child: SectionTitle(
                  title: 'Today\'s Routine',
                  actionText: 'View All',
                  onActionPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoutineScreen()),
                    );
                  },
                ),
              ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: AppMotion.staggerDelay(3),
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildRoutineSummaryCard(context),
              ),
              ),
            ),

            // Today's Cherished Memory Spotlight
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: AppMotion.staggerDelay(4),
                child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
                child: SectionTitle(
                  title: 'Memory of the Day',
                  actionText: 'Albums',
                  onActionPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MemoriesScreen()),
                    );
                  },
                ),
              ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: AppMotion.staggerDelay(4),
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildMemorySpotlightCard(context),
              ),
              ),
            ),

            // Memory Garden entry — the personal memory graph
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: AppMotion.staggerDelay(4),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildMemoryGardenCard(context),
                ),
              ),
            ),

            // Photo Memory companion — capture a photo through gentle Q&A
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: AppMotion.staggerDelay(4),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _buildPhotoMemoryCard(context),
                ),
              ),
            ),

            // Quick Activities Section
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: AppMotion.staggerDelay(5),
                child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
                child: SectionTitle(
                  title: 'Play & Remember',
                  actionText: 'More',
                  onActionPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
                    );
                  },
                ),
              ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: AppMotion.staggerDelay(5),
                child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: _buildActivityRow(context),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Memory Garden entry card ──
  // Opens the visual personal memory graph (people, places, events…).
  Widget _buildMemoryGardenCard(BuildContext context) {
    return AnimatedScaleButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MemoryGardenScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radius28),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.divider, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.paleSage,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa_rounded,
                  color: AppTheme.forest, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Memory Garden',
                      style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.deepForest)),
                  const SizedBox(height: 2),
                  Text('See your family, places and moments — connected',
                      style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.muted,
                          height: 1.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.forest),
          ],
        ),
      ),
    );
  }

  // ── Photo Memory companion entry card ──
  // Opens the guided photo → Q&A → structured memory loop.
  Widget _buildPhotoMemoryCard(BuildContext context) {
    return AnimatedScaleButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PhotoMemoryScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radius28),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.divider, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppTheme.paleCoral,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera_front_rounded,
                  color: AppTheme.coral, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Share a photo with Saathi',
                      style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.deepForest)),
                  const SizedBox(height: 2),
                  Text('Tell me about a picture, and I\'ll remember it',
                      style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.muted,
                          height: 1.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.forest),
          ],
        ),
      ),
    );
  }

  // ── "Talk to AI Saathi" hero card ──
  // A warm companion portrait + a green mic button. Tapping anywhere
  // opens the AI Saathi chat/voice conversation screen.
  Widget _buildTalkToSaathiCard(BuildContext context) {
    return AnimatedScaleButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SaathiScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.deepHeroGradient,
          borderRadius: BorderRadius.circular(AppTheme.radius28),
          boxShadow: AppTheme.elevatedShadow,
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          children: [
            // Companion avatar / portrait
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFDF3DD), Color(0xFFF6E2BC)],
                ),
                border: Border.all(color: AppTheme.warmAmber, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warmAmber.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_emotions_rounded,
                color: AppTheme.warmAmber,
                size: 44,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.warmAmber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AI COMPANION',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.deepForest,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Talk to AI Saathi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to start a warm, caring conversation',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Green mic button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1FB577), Color(0xFF0D5C46)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.emerald.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radius24),
        border: Border.all(color: AppTheme.divider, width: 1.3),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.sage,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.alarm_on_rounded,
                  color: AppTheme.forest,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Morning Conversation',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '9:00 AM • Completed with Saathi',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Next: Memory activity at 11:00 AM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.muted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoutineScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Open Routine'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemorySpotlightCard(BuildContext context) {
    final memories = MemoryService().memories;
    final hasMemories = memories.isNotEmpty;
    final memory = hasMemories ? memories.first : null;

    return AnimatedScaleButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MemoriesScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(AppTheme.radius24),
          border: Border.all(color: AppTheme.divider, width: 1.3),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: hasMemories ? memory!.color : AppTheme.sage,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                hasMemories ? memory!.icon : Icons.bookmark_add_rounded,
                size: 36,
                color: AppTheme.forest,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.paleTerracotta,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hasMemories ? memory!.category : 'Memories',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.terracotta,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasMemories ? memory!.title : 'Start Your Memory Book',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.deepForest,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasMemories
                        ? memory!.subtitle
                        : 'Add favorite moments, family stories & joyful memories.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: AppTheme.forest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _activityTile(
            title: 'Memory Match',
            subtitle: '5 min brain game',
            icon: Icons.psychology_rounded,
            color: AppTheme.sage,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _activityTile(
            title: 'Familiar Music',
            subtitle: 'Old devotional songs',
            icon: Icons.music_note_rounded,
            color: AppTheme.lavender,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _activityTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          border: Border.all(color: AppTheme.divider, width: 1.2),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.forest, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.deepForest,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
