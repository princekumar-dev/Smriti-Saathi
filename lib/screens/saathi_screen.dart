import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/app_shell.dart';
import '../data/repositories/chat_repository.dart';
import '../services/saathi_ai_engine.dart';
import '../services/speech_service.dart';
import '../services/voice_engine.dart';
import '../state/app_settings.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/fx/voice_waveform.dart';
import '../widgets/offline_ai_modal.dart';

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
    with TickerProviderStateMixin {
  final SpeechService _speech = SpeechService();
  final TextEditingController _textController = TextEditingController();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  double _soundLevel = 0.0;
  String _activeMessage = 'Namaste... I am Saathi, your companion. I am right here listening with you.';
  String _userSpoken = '';
  String? _micStatusNotice;
  bool _greetingInitialized = false;

  late AnimationController _orbController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  final List<_ChatMessage> _conversation = [];

  final ChatRepository _chatRepo = ChatRepository();
  String? _patientId;
  bool _chatLoaded = false;

  final List<_PromptItem> _prompts = [
    _PromptItem(Icons.schedule_rounded, 'What is on my schedule today?'),
    _PromptItem(Icons.family_restroom_rounded, 'Who is my daughter Meena?'),
    _PromptItem(Icons.auto_stories_rounded, 'Tell me a peaceful childhood story'),
    _PromptItem(Icons.medication_rounded, 'Did I take my morning medicine?'),
    _PromptItem(Icons.access_time_rounded, 'What time is it right now?'),
    _PromptItem(Icons.home_rounded, 'Tell me about our old family house'),
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    VoiceEngine().addListener(_onVoiceEngineChanged);
  }

  void _onVoiceEngineChanged() {
    if (mounted) {
      setState(() {
        _isSpeaking = VoiceEngine().isSpeaking;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_greetingInitialized) {
      _greetingInitialized = true;
      final settings = AppSettingsScope.of(context);
      try {
        final auth = AuthScope.of(context);
        final gender = auth.activePatient?.gender;
        if (gender != null && gender.isNotEmpty) {
          settings.autoSyncWithGender(gender);
        }
      } catch (_) {}
      _activeMessage = _getDefaultGreeting(settings.language);
    }
    if (!_chatLoaded) {
      _chatLoaded = true;
      try {
        _patientId = AuthScope.of(context).activePatient?.id;
      } catch (_) {}
      _loadChatHistory();
    }
  }

  /// Rehydrate past conversation from the local (offline-first) chat store so
  /// Saathi "remembers" what was said before, across app restarts.
  void _loadChatHistory() {
    try {
      final history = _chatRepo.history(patientId: _patientId);
      final pairs = <_ChatMessage>[];
      String? pendingUser;
      for (final row in history) {
        final role = row['role']?.toString() ?? '';
        final text = row['text']?.toString() ?? '';
        final ts = DateTime.fromMillisecondsSinceEpoch(
            (row['ts'] as num?)?.toInt() ?? 0);
        if (role == 'user') {
          pendingUser = text;
        } else if (role == 'saathi') {
          pairs.add(_ChatMessage(
            userText: pendingUser ?? '',
            aiReply: text,
            timestamp: ts,
          ));
          pendingUser = null;
        }
      }
      if (pairs.isNotEmpty) {
        setState(() {
          // Newest first, matching how new turns are inserted at index 0.
          _conversation
            ..clear()
            ..addAll(pairs.reversed);
        });
      }
    } catch (_) {}
  }

  String _getDefaultGreeting(String language) {
    final l = language.toLowerCase();
    if (l.contains('tamil') || l.contains('தமிழ்')) {
      return 'வணக்கம்... நான் உங்கள் தோழன் ஸ்மிருதி சாதி. நான் உங்களுடனேயே இருக்கிறேன், இன்று உங்கள் மனம் எப்படி இருக்கிறது?';
    }
    if (l.contains('telugu') || l.contains('తెలుగు')) {
      return 'నమస్కారం... నేను మీ స్మృతి సాథిని. నేను మీతోనే ఉన్నాను, ఈ రోజు మీ మనసు ఎలా ఉంది?';
    }
    if (l.contains('kannada') || l.contains('ಕನ್ನಡ')) {
      return 'ನಮಸ್ಕಾರ... ನಾನು ನಿಮ್ಮ ಸ್ಮೃತಿ ಸಾಥಿ. ನಾನು ನಿಮ್ಮೊಂದಿಗಿದ್ದೇನೆ, ಇಂದು ನಿಮ್ಮ ಮನಸ್ಸು ಹೇಗಿದೆ?';
    }
    if (l.contains('malayalam') || l.contains('മലയാളം')) {
      return 'നമസ്കാരം... ഞാൻ നിങ്ങളുടെ സ്മൃതി സാഥി. ഞാൻ നിങ്ങളുടെ കൂടെയുണ്ട്, ഇന്ന് മനസ്സിന് എങ്ങനെയുണ്ട്?';
    }
    if (l.contains('marathi') || l.contains('मराठी')) {
      return 'नमस्कार... मी स्मृती साथी आहे. मी तुमच्यासोबतच आहे, सांगा आज तुम्हाला कसे वाटत आहे?';
    }
    if (l.contains('gujarati') || l.contains('ગુજરાતી')) {
      return 'નમસ્તે... હું તમારી સ્મૃતિ સાથી છું. હું તમારી સાથે જ છું, કહો આજે કેવું લાગે છે?';
    }
    if (l.contains('punjabi') || l.contains('ਪੰਜਾਬੀ')) {
      return 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ... ਮੈਂ ਤੁਹਾਡਾ ਸਮ੍ਰਿਤੀ ਸਾਥੀ ਹਾਂ। ਮੈਂ ਤੁਹਾਡੇ ਨਾਲ ਹਾਂ, ਦੱਸੋ ਅੱਜ ਤੁਹਾਡਾ ਮਨ ਕਿਹੋ ਜਿਹਾ ਹੈ?';
    }
    if (l.contains('odia') || l.contains('oriya') || l.contains('ଓଡ଼ିଆ')) {
      return 'ନମସ୍କାର... ମୁଁ ଆପଣଙ୍କ ସ୍ମୃତି ସାଥୀ। ମୁଁ ଆପଣଙ୍କ ସାଥିରେ ଅଛି, କୁହନ୍ତୁ ଆଜି କିପରି ଅନୁଭବ କରୁଛନ୍ତି?';
    }
    if (l.contains('assam') || l.contains('অসমীয়া')) {
      return 'নমস্কাৰ... মই আপোনাৰ সংগী স্মৃতি সাথী। মই আপোনাৰ ওচৰতেই আছো, কওকচোন আজি আপোনাৰ মনটো কেনে লাগিছে?';
    }
    if (l.contains('bengal') || l.contains('বাংলা')) {
      return 'নমস্কার... আমি আপনার সঙ্গী স্মৃতি সাথী। আমি আপনার কাছেই আছি, বলুন আজ আপনার কেমন লাগছে?';
    }
    if (l.contains('manipuri') || l.contains('meitei') || l.contains('মৈতৈ')) {
      return 'খুরুমজরি... ঐহাক নখোইগী সাথীনি। ঐহাক নখোইগা লোয়ননা লৈরি, ঙসি অদোমগী ৱাখলদা করি ফাওই?';
    }
    if (l.contains('mizo')) {
      return 'Chibai... Kei hi Saathi ka ni e. I kiangah ka awm reng e, vawiin chu eng nge i an le?';
    }
    if (l.contains('nepal') || l.contains('नेपाली')) {
      return 'नमस्ते... म तपाईंको साथी स्मृति साथी हुँ। म तपाईंसँगै छु, भन्नुहोस् आज तपाईंलाई कस्तो महसुस भइरहेको छ?';
    }
    if (l.contains('hindi') || l.contains('हिंदी') || l.contains('हिन्दी')) {
      return 'नमस्ते... मैं साथी हूँ, आपका अपना साथी। मैं आपके साथ यहीं हूँ, बताइए आज आप कैसा महसूस कर रहे हैं?';
    }
    return 'Hello... I am Saathi, your companion. I am right here with you, how are you feeling today?';
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
    VoiceEngine().removeListener(_onVoiceEngineChanged);
    VoiceEngine().stop();
    _speech.stopListening();
    _orbController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _speakResponse(String text) async {
    try {
      final settings = AppSettingsScope.of(context);
      if (!settings.voiceResponses) return;
      await VoiceEngine().speak(
        text,
        language: settings.language,
        rate: settings.voiceRate,
        pitch: settings.voicePitch,
      );
    } catch (_) {}
  }

  String _getUserName() {
    try {
      final auth = AuthScope.of(context);
      if (auth.activePatient != null && auth.activePatient!.nickname.isNotEmpty) {
        return auth.activePatient!.nickname;
      }
      if (auth.activePatient != null && auth.activePatient!.name.isNotEmpty) {
        return auth.activePatient!.name;
      }
    } catch (_) {}
    return '';
  }

  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();

    if (_isListening) {
      await _speech.stopListening();
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
      if (_userSpoken.trim().isNotEmpty &&
          _userSpoken != 'Listening to your voice...' &&
          _userSpoken != 'Listening with care...') {
        await _processUserQuery(_userSpoken);
      }
      return;
    }

    final settings = AppSettingsScope.of(context);
    final userName = _getUserName();
    await VoiceEngine().stop();
    setState(() {
      _isSpeaking = false;
      _isListening = true;
      _soundLevel = 0.0;
      _userSpoken = 'Listening with care...';
      _activeMessage = userName.isNotEmpty
          ? 'I am listening with love, $userName... Take your time.'
          : 'I am listening with love... Take your time.';
      _micStatusNotice = null;
    });

    final started = await _speech.startListening(
      language: settings.language,
      onSoundLevelChange: (level) {
        if (!mounted || !_isListening) return;
        setState(() => _soundLevel = level);
      },
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _userSpoken = text.isNotEmpty ? text : 'Listening with care...';
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
    final currentLang = AppSettingsScope.of(context).language;

    await _speech.stopListening();

    setState(() {
      _isListening = false;
      _isProcessing = true;
      _userSpoken = '"$clean"';
      _activeMessage = 'Listening and reflecting with you...';
    });

    final userName = _getUserName();
    final response = await SaathiAiEngine.generateResponse(
      query: clean,
      userName: userName,
      language: currentLang,
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

    await _speakResponse(response.text);

    // Persist the turn offline-first so the conversation survives restarts.
    try {
      await _chatRepo.addMessage(
          role: 'user', text: clean, patientId: _patientId);
      await _chatRepo.addMessage(
          role: 'saathi', text: response.text, patientId: _patientId);
    } catch (_) {}
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

  Color _getStateColor() {
    if (_isListening) return const Color(0xFFD4870E);
    if (_isSpeaking) return AppTheme.forest;
    if (_isProcessing) return const Color(0xFF7B2D8E);
    return AppTheme.forest;
  }

  String _getStateLabel() {
    if (_isListening) return 'LISTENING';
    if (_isSpeaking) return 'SPEAKING';
    if (_isProcessing) return 'THINKING';
    return 'READY';
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();
    final stateColor = _getStateColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Premium Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              child: Row(
                children: [
                  // Companion avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFDF3DD), Color(0xFFF6E2BC)],
                      ),
                      border: Border.all(color: AppTheme.warmAmber, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.warmAmber.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_emotions_rounded,
                      color: AppTheme.warmAmber,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Saathi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.deepForest,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? const Color(0xFFD4870E)
                                    : (_isSpeaking ? AppTheme.emerald : AppTheme.muted),
                                shape: BoxShape.circle,
                                boxShadow: (_isListening || _isSpeaking)
                                    ? [
                                        BoxShadow(
                                          color: (_isListening
                                                  ? const Color(0xFFD4870E)
                                                  : AppTheme.emerald)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isListening
                                  ? 'Listening to you'
                                  : (_isSpeaking ? 'Speaking gently' : 'Ready to chat'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _isListening
                                    ? const Color(0xFFD4870E)
                                    : (_isSpeaking ? AppTheme.forest : AppTheme.muted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badges
                  GestureDetector(
                    onTap: () => OfflineAiModal.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.forest.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.forest.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_bolt_rounded, size: 13, color: AppTheme.forest),
                          SizedBox(width: 4),
                          Text(
                            'Offline AI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings_outlined, size: 22, color: AppTheme.deepForest),
                    onPressed: () => openSettings(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _fadeController,
                    curve: Curves.easeOut,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),

                      // ── Daily Check-In Callout ──
                      _buildDailyCallout(userName),

                      const SizedBox(height: 16),

                      // ── Voice Bubble ──
                      _buildVoiceBubble(stateColor),

                      if (_micStatusNotice != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Text(
                            _micStatusNotice!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.muted,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── Breathing Orb ──
                      _buildOrb(stateColor),

                      const SizedBox(height: 14),

                      // ── State Label ──
                      _buildStateLabel(),

                      const SizedBox(height: 24),

                      // ── Suggested Questions ──
                      _buildPromptsSection(),

                      // ── Conversation History ──
                      if (_conversation.length > 1) ...[
                        const SizedBox(height: 24),
                        _buildConversationHistory(),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // ── Input Bar ──
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCallout(String userName) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFEF7E8),
            const Color(0xFFFFF3D6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.warmAmber.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmAmber.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warmAmber.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Wellbeing Voice Routine',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.deepForest,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Answer morning check-in & medicine routine',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.muted.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => VoiceCheckinDialog.show(context, userName: userName),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              shadowColor: AppTheme.forest.withValues(alpha: 0.3),
            ),
            child: const Text(
              'Start',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceBubble(Color stateColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: stateColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          ...AppTheme.softShadow,
        ],
        border: Border.all(
          color: stateColor.withValues(alpha: _isListening || _isSpeaking ? 0.4 : 0.12),
          width: _isListening || _isSpeaking ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // State Badge + Controls
          Row(
            children: [
              // Animated state pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing dot
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) {
                        return Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: stateColor.withValues(
                              alpha: 0.5 + (_pulseController.value * 0.5),
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStateLabel(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: stateColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Audio controls
              if (_isSpeaking)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    VoiceEngine().stop();
                    setState(() => _isSpeaking = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.coral.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stop_rounded,
                      color: AppTheme.coral,
                      size: 20,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _speakResponse(_activeMessage);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.forest.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: AppTheme.forest,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),

          // User Spoken Text
          if (_userSpoken.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5EF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: stateColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _userSpoken,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        fontStyle: _isListening ? FontStyle.normal : FontStyle.italic,
                        color: AppTheme.deepForest,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Saathi Response
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppTheme.emeraldGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _activeMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepForest,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(Color stateColor) {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _orbController,
        builder: (context, _) {
          final pulse = _orbController.value;

          // Live voice amplitude (0..1), from speech_to_text's ~-2..10 range.
          final voice = _isListening
              ? ((_soundLevel + 2) / 12).clamp(0.0, 1.0)
              : 0.0;

          final outerScale = 1.0 +
              (pulse * (_isListening ? 0.3 : 0.12)) +
              (voice * 0.22);
          final midScale = 1.0 +
              (pulse * (_isListening ? 0.2 : 0.08)) +
              (voice * 0.14);
          final coreScale = 1.0 + (voice * 0.12);
          final glowOpacity = _isListening
              ? (0.35 + voice * 0.3)
              : (_isSpeaking ? 0.2 : 0.1);

          return SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outermost glow ring
                Transform.scale(
                  scale: outerScale,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          stateColor.withValues(alpha: glowOpacity * 0.5),
                          stateColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Outer ring
                Transform.scale(
                  scale: outerScale * 0.95,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stateColor.withValues(alpha: 0.08),
                      border: Border.all(
                        color: stateColor.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // Middle ring
                Transform.scale(
                  scale: midScale,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.sage.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                // Inner glow ring
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stateColor.withValues(alpha: 0.06),
                  ),
                ),
                // Core orb
                Transform.scale(
                  scale: coreScale,
                  child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isListening
                          ? [const Color(0xFFE8B84B), const Color(0xFFD4870E)]
                          : _isSpeaking
                              ? [const Color(0xFF1A9E6A), AppTheme.forest]
                              : [const Color(0xFF1A9E6A), const Color(0xFF0D5C46)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: stateColor.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: stateColor.withValues(alpha: 0.15),
                        blurRadius: 48,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: (_isListening || _isSpeaking)
                        ? VoiceWaveform(
                            key: ValueKey(_isListening ? 'wave_listen' : 'wave_speak'),
                            active: true,
                            level: _isListening ? _soundLevel : null,
                            color: Colors.white,
                            height: 34,
                          )
                        : const Icon(
                            Icons.mic_rounded,
                            key: ValueKey('idle'),
                            size: 42,
                            color: Colors.white,
                          ),
                  ),
                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateLabel() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isListening
                ? 'Listening with love'
                : (_isSpeaking
                    ? 'Saathi is speaking'
                    : (_isProcessing ? 'Reflecting with you' : 'Tap to speak')),
            key: ValueKey(_isListening ? 'l' : (_isSpeaking ? 's' : (_isProcessing ? 'p' : 'i'))),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.deepForest,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isListening
              ? 'Take your time, I hear every word'
              : (_isSpeaking ? 'You can tap to stop anytime' : 'Talk about anything or pick a topic'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.muted.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: AppTheme.forest),
            SizedBox(width: 6),
            Text(
              'Suggested Questions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppTheme.deepForest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._prompts.map((prompt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnimatedScaleButton(
              onTap: () {
                HapticFeedback.lightImpact();
                _processUserQuery(prompt.text);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.paper,
                      AppTheme.paper.withValues(alpha: 0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.divider.withValues(alpha: 0.8),
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
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.forest.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        prompt.icon,
                        size: 18,
                        color: AppTheme.forest,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        prompt.text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepForest,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppTheme.muted.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConversationHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_rounded, size: 16, color: AppTheme.forest),
            SizedBox(width: 6),
            Text(
              'Recent Conversations',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppTheme.deepForest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._conversation.skip(1).map((msg) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.deepForest.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.forest.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.person_rounded, size: 14, color: AppTheme.forest),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        msg.userText,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.deepForest,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: AppTheme.emeraldGradient,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        msg.aiReply,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (msg.suggestedAction != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => _handleSuggestedAction(msg.suggestedAction!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.forest.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_new_rounded, size: 13, color: AppTheme.forest),
                            const SizedBox(width: 4),
                            Text(
                              'Open ${msg.suggestedAction!}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.forest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepForest.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppTheme.divider.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F1EA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider.withValues(alpha: 0.6)),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: (_) => _submitTextInput(),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.deepForest,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a question for Saathi...',
                  hintStyle: TextStyle(
                    color: AppTheme.muted.withValues(alpha: 0.65),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: AppTheme.muted.withValues(alpha: 0.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _submitTextInput();
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppTheme.emeraldGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.forest.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
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

class _PromptItem {
  final IconData icon;
  final String text;

  const _PromptItem(this.icon, this.text);
}
