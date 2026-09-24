import 'package:flutter/material.dart';

import '../data/repositories/game_score_repository.dart';
import '../services/memory_game_engine.dart';
import '../services/memory_graph_service.dart';
import '../state/auth_state.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/fx/fade_slide_in.dart';
import '../widgets/screen_header.dart';
import 'games/memory_quiz_screen.dart';

/// Play & activities — personalised memory games built from the user's own
/// memory graph (§14–15), never generic trivia. Each card launches a gentle
/// round of [MemoryQuizScreen] and shows how it went last time.
class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  String? _patientId;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bind());
  }

  void _bind() {
    final auth = AuthScope.of(context);
    _patientId = auth.activePatient?.id;
    MemoryGraphService().bindPatient(_patientId);
    setState(() => _ready = true);
  }

  static const _games = <_GameDef>[
    _GameDef(
      gameId: 'quiz_who_is_this',
      title: 'Who is this?',
      description: 'Recognise the people you love',
      icon: Icons.face_retouching_natural_rounded,
      color: AppTheme.sage,
      kind: GameQuestionKind.whoIsThis,
    ),
    _GameDef(
      gameId: 'quiz_relation',
      title: 'Family & friends',
      description: 'Who is who in your life',
      icon: Icons.diversity_1_rounded,
      color: AppTheme.paleTerracotta,
      kind: GameQuestionKind.relationOf,
    ),
    _GameDef(
      gameId: 'quiz_who_was_with',
      title: 'Who was there?',
      description: 'Remember happy moments together',
      icon: Icons.groups_rounded,
      color: AppTheme.lavender,
      kind: GameQuestionKind.whoWasWith,
    ),
    _GameDef(
      gameId: 'quiz_mixed',
      title: 'A little of everything',
      description: 'A gentle mix, made just for you',
      icon: Icons.auto_awesome_rounded,
      color: AppTheme.sand,
      kind: null,
    ),
  ];

  Future<void> _play(_GameDef g) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemoryQuizScreen(
          title: g.title,
          gameId: g.gameId,
          kind: g.kind,
        ),
      ),
    );
    if (mounted) setState(() {}); // refresh stats on return
  }

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
                subtitle: 'Games made from your own memories',
                icon: canPop ? null : Icons.extension_rounded,
                showBack: canPop,
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: AppMotion.staggerDelay(0),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: HeroBanner(
                    title: 'Keep your mind active',
                    subtitle:
                        'These little games remember the people and places '
                        'from your life. No timer, no pressure.',
                    icon: Icons.lightbulb_rounded,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final g = _games[i];
                    return Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                      child: FadeSlideIn(
                        delay: AppMotion.staggerDelay(i + 1),
                        child: _gameCard(g),
                      ),
                    );
                  },
                  childCount: _games.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameCard(_GameDef g) {
    final repo = GameScoreRepository();
    final played = _ready ? repo.timesPlayed(g.gameId, patientId: _patientId) : 0;
    final best = _ready ? repo.bestScore(g.gameId, patientId: _patientId) : 0;

    return Material(
      color: g.color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _play(g),
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
                child: Icon(g.icon, size: 32, color: AppTheme.forest),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(g.description,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      played == 0
                          ? 'Tap to play'
                          : 'Best $best · played $played time${played == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forest,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Play',
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
}

class _GameDef {
  final String gameId;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final GameQuestionKind? kind;

  const _GameDef({
    required this.gameId,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.kind,
  });
}
