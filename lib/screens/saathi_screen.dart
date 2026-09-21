import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../navigation/app_shell.dart';
import '../services/saathi_ai_engine.dart';
import '../services/speech_service.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/offline_badge.dart';
import '../widgets/voice_checkin_dialog.dart';
import 'activities_screen.dart';
import 'family_screen.dart';
import 'memories_screen.dart';
import 'routine_screen.dart';

class SaathiScreen extends StatefulWidget {
  const SaathiScreen({super.key});

  @override
  State<SaathiScreen> createState() => _SaathiScreenState();
}

class _SaathiScreenState extends State<SaathiScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final SpeechService _speech = SpeechService();
  final TextEditingController _textController = TextEditingController();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  String _activeMessage = 'Namaste! I am Saathi, your companion. Tap the microphone to talk or ask me any question.';
  String _userSpoken = '';
  String? _micStatusNotice;

  late AnimationController _waveController;
  final List<_ChatMessage> _conversation = [];

  final List<String> _prompts = [
    'What is on my schedule today?',
    'Who is my daughter Meena?',
    'Tell me a peaceful childhood story',
    'Did I take my morning medicine?',
    'What time is it right now?',
    'Tell me about our old family house',
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  void _initTts() {
    try {
      _tts.setLanguage('en-IN');
      _tts.setSpeechRate(0.46);
      _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts.setErrorHandler((dynamic _) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (_) {}
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _micStatusNotice = 'Microphone ready. Tap orb again to speak or type below.';
          });
        },
      );
      if (!ok && mounted) {
        setState(() {
          _micStatusNotice = 'Tip: You can speak using the microphone or type any question below.';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stopListening();
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _speakResponse(String text) async {
    try {
      await _tts.stop();
      setState(() => _isSpeaking = true);
      await _tts.speak(text);
    } catch (_) {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  String _getUserName() {
    try {
      final auth = AuthScope.of(context);
      if (auth.activePatient != null && auth.activePatient!.nickname.isNotEmpty) {
        return auth.activePatient!.nickname;
      }
      if (auth.activePatient != null) return auth.activePatient!.name;
    } catch (_) {}
    return 'Amma';
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      // User tapped to finish speaking
      await _speech.stopListening();
      setState(() => _isListening = false);
      if (_userSpoken.trim().isNotEmpty && _userSpoken != 'Listening to your voice...') {
        await _processUserQuery(_userSpoken);
      }
      return;
    }

    // Stop speaking if playing
    await _tts.stop();
    setState(() {
      _isSpeaking = false;
      _isListening = true;
      _userSpoken = 'Listening to your voice...';
      _activeMessage = 'I am listening. Please speak now...';
      _micStatusNotice = null;
    });

    final started = await _speech.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _userSpoken = text.isNotEmpty ? text : 'Listening to your voice...';
        });

        if (isFinal && text.trim().isNotEmpty) {
          _processUserQuery(text);
        }
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'notListening' || status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _micStatusNotice = 'Tap the orb again or type your question below.';
        });
      },
    );

    if (!started && mounted) {
      setState(() {
        _isListening = false;
        _micStatusNotice = 'Microphone prompt: Please allow microphone access or choose a topic below.';
      });
    }
  }

  Future<void> _processUserQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    await _speech.stopListening();

    setState(() {
      _isListening = false;
      _isProcessing = true;
      _userSpoken = '“$clean”';
      _activeMessage = 'Thinking and answering...';
    });

    final userName = _getUserName();
    final response = await SaathiAiEngine.generateResponse(
      query: clean,
      userName: userName,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _activeMessage = response.text;
      _conversation.insert(
        0,
        _ChatMessage(
          userText: clean,
          aiReply: response.text,
          timestamp: DateTime.now(),
          suggestedAction: response.suggestedAction,
        ),
      );
    });

    // Speak aloud
    await _speakResponse(response.text);
  }

  void _handleSuggestedAction(String action) {
    if (action == 'memories') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoriesScreen()));
    } else if (action == 'family') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen()));
    } else if (action == 'routine') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutineScreen()));
    } else if (action == 'activities') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivitiesScreen()));
    }
  }

  void _submitTextInput() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    _processUserQuery(text);
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Voice Saathi',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: AppTheme.deepForest),
            onPressed: () => openSettings(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: OfflineBadge(compact: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    // Daily Check-In Floating Callout
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.softGold,
                        borderRadius: BorderRadius.circular(AppTheme.radius20),
                        border: Border.all(color: AppTheme.warmAmber.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.warmAmber,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.record_voice_over_rounded, color: AppTheme.deepForest, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Wellbeing Voice Routine',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.deepForest,
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Answer morning check-in & medicine routine',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => VoiceCheckinDialog.show(context, userName: userName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.forest,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Start', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),

                    // Active Voice Bubble
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.paper,
                        borderRadius: BorderRadius.circular(AppTheme.radius28),
                        boxShadow: AppTheme.softShadow,
                        border: Border.all(
                          color: _isListening
                              ? AppTheme.forest
                              : (_isSpeaking ? AppTheme.warmAmber : AppTheme.divider),
                          width: (_isListening || _isSpeaking) ? 2.0 : 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isListening
                                      ? AppTheme.warmAmber.withValues(alpha: 0.25)
                                      : (_isSpeaking ? AppTheme.paleCoral : AppTheme.sage),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isListening)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: SizedBox(
                                          width: 8,
                                          height: 8,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.deepForest),
                                        ),
                                      ),
                                    Text(
                                      _isListening
                                          ? 'LISTENING TO YOUR VOICE'
                                          : (_isSpeaking
                                              ? 'SPEAKING ALOUD'
                                              : (_isProcessing ? 'THINKING' : 'SAATHI COMPANION')),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.deepForest,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (_isSpeaking)
                                IconButton(
                                  icon: const Icon(Icons.stop_circle_rounded, color: AppTheme.coral, size: 28),
                                  tooltip: 'Stop Voice',
                                  onPressed: () {
                                    _tts.stop();
                                    setState(() => _isSpeaking = false);
                                  },
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.volume_up_rounded, color: AppTheme.forest, size: 24),
                                  tooltip: 'Hear Again',
                                  onPressed: () => _speakResponse(_activeMessage),
                                ),
                            ],
                          ),
                          if (_userSpoken.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.cream,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.record_voice_over_rounded, size: 18, color: AppTheme.forest),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _userSpoken,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        fontStyle: _isListening ? FontStyle.normal : FontStyle.italic,
                                        color: AppTheme.deepForest,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            _activeMessage,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepForest,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_micStatusNotice != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _micStatusNotice!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Breathing Voice Visualizer Orb
                    Center(
                      child: GestureDetector(
                        onTap: _toggleListening,
                        child: AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, _) {
                            final pulse = _waveController.value;
                            final scale1 = 1.0 + (pulse * (_isListening ? 0.28 : 0.12));
                            final scale2 = 1.0 + (pulse * (_isListening ? 0.16 : 0.06));

                            return SizedBox(
                              width: 190,
                              height: 190,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer Ring
                                  Transform.scale(
                                    scale: scale1,
                                    child: Container(
                                      width: 170,
                                      height: 170,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (_isListening ? AppTheme.warmAmber : AppTheme.emerald)
                                            .withValues(alpha: _isListening ? 0.3 : 0.15),
                                      ),
                                    ),
                                  ),
                                  // Middle Ring
                                  Transform.scale(
                                    scale: scale2,
                                    child: Container(
                                      width: 138,
                                      height: 138,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.sage.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ),
                                  // Core Orb
                                  Container(
                                    width: 104,
                                    height: 104,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: _isListening
                                          ? AppTheme.goldGradient
                                          : AppTheme.emeraldGradient,
                                      boxShadow: _isListening
                                          ? AppTheme.amberGlow
                                          : AppTheme.emeraldGlow,
                                    ),
                                    child: Icon(
                                      _isListening
                                          ? Icons.graphic_eq_rounded
                                          : (_isSpeaking ? Icons.volume_up_rounded : Icons.mic_rounded),
                                      size: 46,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _isListening
                          ? 'Listening live… Tap to finish'
                          : (_isSpeaking ? 'Saathi is answering out loud' : 'Tap Orb to Speak'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isListening
                          ? 'Speak naturally in English or your language'
                          : 'Ask anything or tap a question below',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.muted,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Suggested Voice Questions
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Suggested Questions to Ask:',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.deepForest,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._prompts.map((prompt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AnimatedScaleButton(
                          onTap: () => _processUserQuery(prompt),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.paper,
                              borderRadius: BorderRadius.circular(AppTheme.radius18),
                              border: Border.all(color: AppTheme.divider, width: 1.2),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.sage,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 18,
                                    color: AppTheme.forest,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    prompt,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.deepForest,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 15,
                                  color: AppTheme.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Conversation History
                    if (_conversation.length > 1) ...[
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent Conversations:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.deepForest,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._conversation.skip(1).map((msg) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.paper,
                            borderRadius: BorderRadius.circular(AppTheme.radius16),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.forest),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      msg.userText,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.deepForest,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.support_agent_rounded, size: 16, color: AppTheme.warmAmber),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      msg.aiReply,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.deepForest,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (msg.suggestedAction != null) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () => _handleSuggestedAction(msg.suggestedAction!),
                                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                    label: Text("Open ${msg.suggestedAction!}"),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Type / Speak input bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: AppTheme.paper,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepForest.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: const Border(
                  top: BorderSide(color: AppTheme.divider, width: 1.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (_) => _submitTextInput(),
                      decoration: InputDecoration(
                        hintText: 'Type any question or speak above...',
                        hintStyle: const TextStyle(color: AppTheme.muted, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius24),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius24),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius24),
                          borderSide: const BorderSide(color: AppTheme.forest, width: 1.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedScaleButton(
                    onTap: _submitTextInput,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.forest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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

class _ChatMessage {
  final String userText;
  final String aiReply;
  final DateTime timestamp;
  final String? suggestedAction;

  const _ChatMessage({
    required this.userText,
    required this.aiReply,
    required this.timestamp,
    this.suggestedAction,
  });
}
