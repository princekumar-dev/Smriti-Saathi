import 'package:flutter/material.dart';

import '../navigation/app_shell.dart';
import '../services/memory_service.dart';
import '../state/auth_session.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/offline_badge.dart';
import '../widgets/section_title.dart';
import '../widgets/voice_checkin_dialog.dart';
import 'activities_screen.dart';
import 'memories_screen.dart';
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

  final List<_MoodOption> _moods = const [
    _MoodOption(label: 'Happy', icon: Icons.sentiment_very_satisfied_rounded, color: AppTheme.warmAmber),
    _MoodOption(label: 'Peaceful', icon: Icons.spa_rounded, color: AppTheme.emerald),
    _MoodOption(label: 'Thoughtful', icon: Icons.menu_book_rounded, color: AppTheme.coral),
    _MoodOption(label: 'Resting', icon: Icons.bedtime_rounded, color: Color(0xFF7A68A6)),
  ];

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getUserName(BuildContext context) {
    try {
      final auth = AuthScope.of(context);
      if (auth.activePatient != null && auth.activePatient!.nickname.isNotEmpty) {
        return auth.activePatient!.nickname;
      }
      if (auth.activePatient != null) return auth.activePatient!.name;
    } catch (_) {}

    try {
      final legacy = AuthSessionScope.of(context);
      if (legacy.activePatient != null) return legacy.activePatient!.name;
      return legacy.displayName;
    } catch (_) {}

    return 'Amma';
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
                            '$_greeting, $userName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.deepForest,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Smriti Saathi is ready',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: _buildHeroVoiceCard(context),
              ),
            ),

            // Mood Tracker Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How are you feeling right now?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _moods.map((m) {
                        final isSelected = _selectedMood == m.label;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedScaleButton(
                              onTap: () {
                                setState(() => _selectedMood = m.label);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Noted, feeling ${m.label}. Saathi is with you.'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? m.color : AppTheme.paper,
                                  borderRadius: BorderRadius.circular(AppTheme.radius18),
                                  boxShadow: isSelected ? AppTheme.softShadow : [],
                                  border: Border.all(
                                    color: isSelected ? m.color : AppTheme.divider,
                                    width: isSelected ? 2.0 : 1.2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      m.icon,
                                      size: 26,
                                      color: isSelected ? Colors.white : m.color,
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        m.label,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: isSelected ? Colors.white : AppTheme.deepForest,
                                        ),
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

            // Daily Routine Preview Section
            SliverToBoxAdapter(
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildRoutineSummaryCard(context),
              ),
            ),

            // Today's Cherished Memory Spotlight
            SliverToBoxAdapter(
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildMemorySpotlightCard(context),
              ),
            ),

            // Quick Activities Section
            SliverToBoxAdapter(
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: _buildActivityRow(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroVoiceCard(BuildContext context) {
    final userName = _getUserName(context);

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.deepHeroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius28),
        boxShadow: AppTheme.elevatedShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warmAmber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VOICE COMPANION READY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.deepForest,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Daily Voice Saathi',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Answer daily questions with your voice & speak commands naturally.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AnimatedScaleButton(
                      onTap: () {
                        VoiceCheckinDialog.show(context, userName: userName);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.warmAmber,
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic_rounded, color: AppTheme.deepForest, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Voice Check-In',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.deepForest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedScaleButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SaathiScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.forest, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Chat Companion',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.deepForest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          BreathingOrb(
            size: 90,
            icon: Icons.graphic_eq_rounded,
            onTap: () {
              VoiceCheckinDialog.show(context, userName: userName);
            },
          ),
        ],
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

class _MoodOption {
  final String label;
  final IconData icon;
  final Color color;

  const _MoodOption({
    required this.label,
    required this.icon,
    required this.color,
  });
}
