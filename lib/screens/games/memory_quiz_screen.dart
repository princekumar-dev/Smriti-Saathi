import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/repositories/game_score_repository.dart';
import '../../services/memory_game_engine.dart';
import '../../services/memory_graph_service.dart';
import '../../services/voice_engine.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_scale_button.dart';
import '../../widgets/screen_header.dart';
import '../memory_garden_screen.dart';

/// A gentle, personalised memory quiz. Questions come from the user's own
/// memory graph via [MemoryGameEngine]; there is no timer and no penalty for
/// "I'm not sure" — the tone stays warm and encouraging (§14).
class MemoryQuizScreen extends StatefulWidget {
  final String title;
  final String gameId;
  final GameQuestionKind? kind;

  const MemoryQuizScreen({
    super.key,
    required this.title,
    required this.gameId,
    this.kind,
  });

  @override
  State<MemoryQuizScreen> createState() => _MemoryQuizScreenState();
}

class _MemoryQuizScreenState extends State<MemoryQuizScreen> {
  List<GameQuestion> _questions = const [];
  int _index = 0;
  int _correct = 0;
  int? _selected; // chosen option index for the current question
  bool _revealed = false;
  bool _finished = false;
  bool _loading = true;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = AuthScope.of(context);
    _patientId = auth.activePatient?.id;
    MemoryGraphService().bindPatient(_patientId);
    _questions = MemoryGameEngine().generate(kind: widget.kind, count: 5);
    setState(() => _loading = false);
    if (_questions.isNotEmpty) _speakPrompt();
  }

  void _speakPrompt() {
    if (_index < _questions.length) {
      VoiceEngine().speak(_questions[_index].prompt);
    }
  }

  void _choose(int optionIndex) {
    if (_revealed) return;
    final q = _questions[_index];
    final isRight = optionIndex == q.correctIndex;
    setState(() {
      _selected = optionIndex;
      _revealed = true;
      if (isRight) _correct++;
    });
    VoiceEngine().speak(isRight
        ? 'That\'s right. ${q.correctAnswer}.'
        : 'It\'s alright. This is ${q.correctAnswer}.');
  }

  // "I'm not sure" — reveal the answer gently, no penalty (§2 non-judgmental).
  void _notSure() {
    if (_revealed) return;
    final q = _questions[_index];
    setState(() {
      _selected = null;
      _revealed = true;
    });
    VoiceEngine().speak('No worries. This is ${q.correctAnswer}.');
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _revealed = false;
    });
    _speakPrompt();
  }

  Future<void> _finish() async {
    setState(() => _finished = true);
    // Score out of 100, plus 0–3 stars — recorded offline-first.
    final pct = _questions.isEmpty
        ? 0
        : ((_correct / _questions.length) * 100).round();
    final stars = _correct >= _questions.length
        ? 3
        : _correct >= (_questions.length / 2).ceil()
            ? 2
            : _correct > 0
                ? 1
                : 0;
    await GameScoreRepository().recordScore(
      game: widget.gameId,
      score: pct,
      stars: stars,
      patientId: _patientId,
      extra: {'correct': _correct, 'total': _questions.length},
    );
    VoiceEngine().speak(_finishLine());
  }

  String _finishLine() {
    if (_questions.isEmpty) return '';
    if (_correct == _questions.length) {
      return 'Wonderful! You remembered every one.';
    }
    if (_correct == 0) {
      return 'That\'s okay. We can look at these memories together anytime.';
    }
    return 'Well done. You remembered $_correct of ${_questions.length}.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: widget.title, showBack: true),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_questions.isEmpty) return _buildNotEnough();
    if (_finished) return _buildSummary();
    return _buildQuestion(_questions[_index]);
  }

  // Gentle empty state when the graph is too small to build a round.
  Widget _buildNotEnough() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_rounded, size: 64, color: AppTheme.sage),
            const SizedBox(height: 16),
            Text('Let\'s add a few memories first',
                textAlign: TextAlign.center,
                style: GoogleFonts.comfortaa(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepForest)),
            const SizedBox(height: 8),
            Text(
              'Once Saathi knows a few people and moments from your life, '
              'we can play games made just for you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: AppTheme.muted, height: 1.4),
            ),
            const SizedBox(height: 22),
            AnimatedScaleButton(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const MemoryGardenScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppTheme.emeraldGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius18),
                ),
                child: Text('Open Memory Garden',
                    style: AppTheme.buttonText(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(GameQuestion q) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        // Progress
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_questions.length, (i) {
            final done = i < _index || (i == _index && _revealed);
            return Container(
              width: 26,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _index
                    ? AppTheme.forest
                    : done
                        ? AppTheme.sage
                        : AppTheme.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        if (q.imageRef != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius28),
            child: Image(
              image: FileImage(File(q.imageRef!)),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          q.prompt,
          textAlign: TextAlign.center,
          style: GoogleFonts.comfortaa(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepForest,
              height: 1.3),
        ),
        const SizedBox(height: 22),
        ...List.generate(q.options.length,
            (i) => _optionButton(q, i)),
        const SizedBox(height: 10),
        if (!_revealed)
          Center(
            child: TextButton(
              onPressed: _notSure,
              child: Text('I\'m not sure',
                  style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted)),
            ),
          ),
        if (_revealed) ...[
          const SizedBox(height: 8),
          AnimatedScaleButton(
            onTap: _next,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppTheme.emeraldGradient,
                borderRadius: BorderRadius.circular(AppTheme.radius18),
                boxShadow: AppTheme.buttonGlow,
              ),
              child: Text(
                  _index + 1 >= _questions.length ? 'Finish' : 'Continue',
                  style: AppTheme.buttonText(fontSize: 17)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _optionButton(GameQuestion q, int i) {
    final isCorrect = i == q.correctIndex;
    final isChosen = i == _selected;
    Color bg = Colors.white;
    Color border = AppTheme.divider;
    Color fg = AppTheme.deepForest;
    IconData? trailing;
    if (_revealed) {
      if (isCorrect) {
        bg = AppTheme.paleSage;
        border = AppTheme.success;
        fg = AppTheme.success;
        trailing = Icons.check_circle_rounded;
      } else if (isChosen) {
        bg = AppTheme.paleCoral;
        border = AppTheme.coral;
        fg = AppTheme.coral;
        trailing = Icons.cancel_rounded;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScaleButton(
        onTap: () => _choose(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radius18),
            border: Border.all(color: border, width: 1.6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(q.options[i],
                    style: GoogleFonts.dmSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: fg)),
              ),
              if (trailing != null) Icon(trailing, color: fg, size: 26),
            ],
          ),
        ),
      ),
    );
  }

  // Warm completion screen — celebrates effort, never scores harshly (§14).
  Widget _buildSummary() {
    final total = _questions.length;
    final stars = _correct >= total
        ? 3
        : _correct >= (total / 2).ceil()
            ? 2
            : _correct > 0
                ? 1
                : 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final filled = i < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 44,
                    color: filled ? AppTheme.warmAmber : AppTheme.divider,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Text(
              _finishLine(),
              textAlign: TextAlign.center,
              style: GoogleFonts.comfortaa(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepForest,
                  height: 1.3),
            ),
            const SizedBox(height: 10),
            Text(
              'You remembered $_correct of $total.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 16, color: AppTheme.muted, height: 1.4),
            ),
            const SizedBox(height: 28),
            AnimatedScaleButton(
              onTap: _restart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 15),
                decoration: BoxDecoration(
                  gradient: AppTheme.emeraldGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius18),
                  boxShadow: AppTheme.buttonGlow,
                ),
                child: Text('Play again',
                    style: AppTheme.buttonText(fontSize: 17)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text('Done for now',
                  style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted)),
            ),
          ],
        ),
      ),
    );
  }

  void _restart() {
    setState(() {
      _questions = MemoryGameEngine().generate(kind: widget.kind, count: 5);
      _index = 0;
      _correct = 0;
      _selected = null;
      _revealed = false;
      _finished = false;
    });
    if (_questions.isNotEmpty) _speakPrompt();
  }
}
