import 'dart:async';
import 'package:flutter/material.dart';

import '../screens/activities_screen.dart';
import '../screens/family_screen.dart';
import '../screens/memories_screen.dart';
import '../screens/routine_screen.dart';
import '../services/saathi_ai_engine.dart';
import '../services/speech_service.dart';
import '../services/voice_engine.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import 'animated_scale_button.dart';

class VoiceCheckinDialog extends StatefulWidget {
  final String userName;
  final VoidCallback? onCompleted;

  const VoiceCheckinDialog({
    super.key,
    required this.userName,
    this.onCompleted,
  });

  static Future<void> show(BuildContext context, {String userName = 'Amma'}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceCheckinDialog(userName: userName),
    );
  }

  @override
  State<VoiceCheckinDialog> createState() => _VoiceCheckinDialogState();
}

class _VoiceCheckinDialogState extends State<VoiceCheckinDialog>
    with SingleTickerProviderStateMixin {
  final SpeechService _speech = SpeechService();
  late AnimationController _animController;

  bool _isSpeaking = false;
  bool _isListening = false;
  int _currentStep = 0;
  String _currentQuestion = '';
  String _spokenText = '';
  String _assistantReply = '';

  final List<_VoiceStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _initSteps();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    if (_steps.isNotEmpty) {
      _currentQuestion = _steps[0].question;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _askCurrentQuestion();
    });
  }

  void _initSteps() {
    _steps.addAll([
      _VoiceStep(
        title: 'Morning Wellbeing',
        question: 'Namaste ${widget.userName}! How are you feeling today?',
        audioText: 'Namaste ${widget.userName}! How are you feeling today?',
        suggestions: [
          'I am feeling happy and good',
          'Feeling a little tired today',
          'I am peaceful and calm',
        ],
      ),
      _VoiceStep(
        title: 'Medication Check',
        question: 'Did you have your morning breakfast and take your medicine?',
        audioText: 'Did you have your morning breakfast and take your medicine?',
        suggestions: [
          'Yes, I took my morning medicine',
          'Not yet, I will take it now',
          'Remind me after 15 minutes',
        ],
      ),
      _VoiceStep(
        title: 'Voice Command & Companion',
        question: 'What would you like to do right now?',
        audioText: 'What would you like to do right now? You can say: Tell me a story, Show family photos, or Check daily routine.',
        suggestions: [
          'Tell me a peaceful childhood story',
          'Show photos of my family',
          'Open my daily routine',
          'Play devotional music',
        ],
      ),
    ]);
  }

  @override
  void dispose() {
    VoiceEngine().stop();
    _speech.stopListening();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _speak(String text, {VoidCallback? onDone}) async {
    final settings = AppSettingsScope.of(context);
    await _speech.stopListening();
    setState(() {
      _isSpeaking = true;
      _isListening = false;
    });
    try {
      await VoiceEngine().speak(
        text,
        language: settings.language,
        rate: settings.voiceRate,
        pitch: settings.voicePitch,
        onDone: () {
          if (mounted) {
            setState(() => _isSpeaking = false);
            onDone?.call();
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  void _askCurrentQuestion() {
    if (_currentStep < _steps.length) {
      final step = _steps[_currentStep];
      setState(() {
        _currentQuestion = step.question;
        _assistantReply = '';
        _spokenText = '';
      });
      _speak(step.audioText, onDone: () {
        if (mounted) {
          _startSpeechListening();
        }
      });
    }
  }

  Future<void> _startSpeechListening() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _spokenText = 'Listening...';
    });

    final settings = AppSettingsScope.of(context);
    final started = await _speech.startListening(
      language: settings.language,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _spokenText = text;
        });
        if (isFinal && text.trim().isNotEmpty) {
          _handleUserVoiceAnswer(text);
        }
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'notListening' || status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
    );

    if (!started && mounted) {
      setState(() => _isListening = false);
    }
  }

  void _handleUserVoiceAnswer(String answer) async {
    await _speech.stopListening();

    setState(() {
      _spokenText = answer;
      _isListening = false;
    });

    String feedback = '';
    VoidCallback? navigationAction;

    final lower = answer.toLowerCase();

    if (_currentStep == 0) {
      if (lower.contains('happy') || lower.contains('good') || lower.contains('great') || lower.contains('peaceful')) {
        feedback = 'That is wonderful to hear! May your day be filled with joy.';
      } else if (lower.contains('tired') || lower.contains('pain') || lower.contains('sad') || lower.contains('unwell')) {
        feedback = 'Please take plenty of rest. Saathi is right by your side.';
      } else {
        final aiRes = await SaathiAiEngine.generateResponse(query: answer, userName: widget.userName);
        feedback = aiRes.text;
      }
    } else if (_currentStep == 1) {
      if (lower.contains('yes') || lower.contains('took') || lower.contains('done')) {
        feedback = 'Excellent! I have recorded your morning medicine as completed.';
      } else {
        feedback = 'Please drink a glass of warm water and take your medicine shortly.';
      }
    } else if (_currentStep == 2) {
      if (lower.contains('story')) {
        feedback = 'Here is a warm story from back home. Once upon a time under the big mango tree...';
        navigationAction = () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoriesScreen()));
        };
      } else if (lower.contains('photo') || lower.contains('family')) {
        feedback = 'Opening your cherished family album right now.';
        navigationAction = () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen()));
        };
      } else if (lower.contains('routine') || lower.contains('schedule')) {
        feedback = 'Let us look at today\'s schedule.';
        navigationAction = () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutineScreen()));
        };
      } else if (lower.contains('music') || lower.contains('game') || lower.contains('activity')) {
        feedback = 'Let us play some soothing devotional music and brain exercises.';
        navigationAction = () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivitiesScreen()));
        };
      } else {
        final aiRes = await SaathiAiEngine.generateResponse(query: answer, userName: widget.userName);
        feedback = aiRes.text;
        if (aiRes.suggestedAction != null) {
          final act = aiRes.suggestedAction!;
          if (act == 'memories') navigationAction = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoriesScreen()));
          if (act == 'family') navigationAction = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen()));
          if (act == 'routine') navigationAction = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutineScreen()));
          if (act == 'activities') navigationAction = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivitiesScreen()));
        }
      }
    }

    if (!mounted) return;

    setState(() => _assistantReply = feedback);
    await _speak(feedback);

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    if (navigationAction != null) {
      Navigator.pop(context);
      navigationAction();
    } else if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _askCurrentQuestion();
    } else {
      widget.onCompleted?.call();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context);
    }
  }

  void _toggleMic() {
    if (_isListening) {
      _speech.stopListening();
      setState(() => _isListening = false);
    } else {
      _startSpeechListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle & Header
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.sage,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSpeaking ? Icons.volume_up_rounded : Icons.mic_rounded,
                        size: 16,
                        color: AppTheme.forest,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DAILY VOICE CHECK-IN (${_currentStep + 1}/${_steps.length})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.forest,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.muted, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Question / Assistant Bubble
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.paper,
                borderRadius: BorderRadius.circular(AppTheme.radius24),
                boxShadow: AppTheme.softShadow,
                border: Border.all(
                  color: _isSpeaking ? AppTheme.warmAmber : (_isListening ? AppTheme.forest : AppTheme.divider),
                  width: (_isSpeaking || _isListening) ? 2.0 : 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.sage,
                        child: Icon(Icons.support_agent_rounded, size: 18, color: AppTheme.forest),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isListening ? 'Listening for your answer...' : (_isSpeaking ? 'Saathi Speaking' : 'Saathi'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.deepForest,
                        ),
                      ),
                      const Spacer(),
                      // Audio Play button
                      AnimatedScaleButton(
                        onTap: () {
                          if (_currentStep < _steps.length) {
                            _speak(_steps[_currentStep].audioText);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isSpeaking ? AppTheme.warmAmber : AppTheme.sage,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isSpeaking ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                                size: 16,
                                color: _isSpeaking ? Colors.white : AppTheme.forest,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isSpeaking ? 'Playing' : 'Hear Question',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _isSpeaking ? Colors.white : AppTheme.forest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentQuestion,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.deepForest,
                      height: 1.35,
                    ),
                  ),
                  if (_spokenText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.sage,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 16, color: AppTheme.forest),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You: "$_spokenText"',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.forest,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_assistantReply.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _assistantReply,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pulsing Orb & Mic Tap
            Center(
              child: GestureDetector(
                onTap: _toggleMic,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    final pulse = _animController.value;
                    final scale = _isListening ? 1.0 + (pulse * 0.22) : 1.0;

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isListening ? AppTheme.goldGradient : AppTheme.emeraldGradient,
                          boxShadow: _isListening ? AppTheme.amberGlow : AppTheme.emeraldGlow,
                        ),
                        child: Icon(
                          _isListening ? Icons.mic_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),
            Center(
              child: Text(
                _isListening
                    ? 'Listening… Speak your answer'
                    : (_isSpeaking ? 'Saathi is speaking...' : 'Tap to answer with your voice'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.muted,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Voice Answer Chips
            if (_currentStep < _steps.length) ...[
              const Text(
                'Quick Voice Answers:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepForest,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _steps[_currentStep].suggestions.map((sug) {
                  return AnimatedScaleButton(
                    onTap: () => _handleUserVoiceAnswer(sug),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.paper,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.forest.withValues(alpha: 0.3)),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppTheme.forest),
                          const SizedBox(width: 8),
                          Text(
                            sug,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.deepForest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VoiceStep {
  final String title;
  final String question;
  final String audioText;
  final List<String> suggestions;

  const _VoiceStep({
    required this.title,
    required this.question,
    required this.audioText,
    required this.suggestions,
  });
}
