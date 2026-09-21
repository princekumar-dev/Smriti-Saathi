import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ScreenHeader(
                title: 'Play & activities',
                subtitle: 'Choose something you enjoy',
                icon: canPop ? null : Icons.extension_rounded,
                showBack: canPop,
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: HeroBanner(
                  title: 'Keep your mind active',
                  subtitle: 'Small activities can make every day more enjoyable.',
                  icon: Icons.lightbulb_rounded,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _activityCard(
                    context,
                    icon: Icons.psychology_rounded,
                    title: 'Memory Match',
                    description: 'Match familiar things',
                    duration: '5 minutes',
                    color: AppTheme.sage,
                  ),
                  const SizedBox(height: 12),
                  _activityCard(
                    context,
                    icon: Icons.record_voice_over_rounded,
                    title: 'Remember & Tell',
                    description: 'Talk about a memory',
                    duration: '10 minutes',
                    color: AppTheme.paleTerracotta,
                  ),
                  const SizedBox(height: 12),
                  _activityCard(
                    context,
                    icon: Icons.music_note_rounded,
                    title: 'Familiar Music',
                    description: 'Listen and remember',
                    duration: '10 minutes',
                    color: AppTheme.lavender,
                  ),
                  const SizedBox(height: 12),
                  _activityCard(
                    context,
                    icon: Icons.menu_book_rounded,
                    title: 'Finish the Story',
                    description: 'Complete a simple story',
                    duration: '5 minutes',
                    color: AppTheme.sand,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String duration,
    required Color color,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _openActivity(context, title),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 32, color: AppTheme.forest),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(description, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forest,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Start',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openActivity(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.psychology_rounded, size: 48, color: AppTheme.forest),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'This activity is calm and unhurried. Take your time.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.muted,
                    ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Starting $title')),
                    );
                  },
                  child: const Text('Start activity'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
