import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/app_translations.dart';
import 'tts/neural_tts_service.dart';
import 'tts/voice_model_manager.dart';
import 'tts/voice_model_registry.dart';

/// Describes how good the currently-active voice is for the selected language,
/// so the UI can gently guide the user to install a better offline voice pack.
enum VoiceQuality {
  /// A modern neural / natural voice in the correct language is active. Ideal.
  natural,

  /// A native-language voice is active, but it is a basic (non-neural) engine voice.
  basicNative,

  /// No native voice for this language; speaking via Romanized Indian-English companion.
  phoneticFallback,

  /// No usable voice found yet (engine still loading or none installed).
  unavailable,
}

/// Senior-Friendly Voice & Speech Output Engine
/// Handles natural voice selection, multilingual text-to-speech,
/// calibrated pacing, warmth, and text sanitization.
class VoiceEngine extends ChangeNotifier {
  static final VoiceEngine _instance = VoiceEngine._internal();
  factory VoiceEngine() => _instance;
  VoiceEngine._internal() {
    _initTts();
  }

  final FlutterTts _tts = FlutterTts();
  final NeuralTtsService _neuralTts = NeuralTtsService();
  final VoiceModelManager _modelManager = VoiceModelManager();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isNeuralActive = false;
  String? _currentUtterance;
  String _currentLanguage = 'English';
  bool _isUsingPhoneticFallback = false;

  // 0.92 represents relaxed, soothing, elder-tuned conversational pace
  double _speechRate = 0.92;
  double _pitch = 0.98; // Gentle, warm natural vocal pitch
  double _volume = 1.0;
  String _persona = 'female'; // 'female' (Warm Companion) | 'male' (Gentle Companion) | 'auto'
  double _langRateMul = 1.0;
  double _langPitchAdd = 0.0;



  List<dynamic> _availableVoices = [];
  Map<String, String>? _activeVoice;
  VoidCallback? _onDoneCallback;

  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  bool get isNeuralActive => _isNeuralActive;
  VoiceModelManager get modelManager => _modelManager;
  NeuralTtsService get neuralTts => _neuralTts;
  String? get currentUtterance => _currentUtterance;
  String get currentLanguage => _currentLanguage;
  bool get isUsingPhoneticFallback => _isUsingPhoneticFallback;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get persona => _persona;
  List<dynamic> get availableVoices => _availableVoices;
  Map<String, String>? get activeVoice => _activeVoice;

  String get activeVoiceName {
    if (_isNeuralActive) {
      final model = VoiceModelRegistry.getModelFor(
        language: _currentLanguage,
        persona: _persona,
      );
      if (model != null) {
        return '${model.speakerName} (Neural Offline)';
      }
    }
    if (_activeVoice != null && _activeVoice!['name'] != null) {
      final name = _activeVoice!['name']!;
      // Clean up common system prefixes for senior readability
      return name
          .replaceAll('Microsoft ', '')
          .replaceAll('Desktop', '')
          .replaceAll('Online (Natural)', '(Natural)')
          .trim();
    }
    return _persona == 'female' ? 'Warm Companion' : 'Gentle Companion';
  }

  /// Assess how natural/appropriate the active voice is for the current language.
  VoiceQuality get voiceQuality {
    if (_isNeuralActive) return VoiceQuality.natural;
    if (_activeVoice == null || (_activeVoice!['name'] ?? '').isEmpty) {
      return VoiceQuality.unavailable;
    }
    if (_isUsingPhoneticFallback) return VoiceQuality.phoneticFallback;
    final n = (_activeVoice!['name'] ?? '').toLowerCase();
    const naturalMarkers = [
      'natural', 'neural', 'online', 'wavenet',
      'journey', 'studio', 'enhanced', 'premium',
    ];
    if (naturalMarkers.any(n.contains)) return VoiceQuality.natural;
    return VoiceQuality.basicNative;
  }

  /// True when a higher-quality offline voice could meaningfully improve things,
  /// so the UI may surface a gentle "install a better voice" hint.
  bool get canImproveVoiceQuality =>
      voiceQuality == VoiceQuality.phoneticFallback ||
      voiceQuality == VoiceQuality.basicNative ||
      voiceQuality == VoiceQuality.unavailable;

  /// Short, elder-friendly guidance for getting a natural offline voice for the
  /// current language. Platform-aware. Returns '' when the voice is already natural.
  String get voiceQualityGuidance {
    switch (voiceQuality) {
      case VoiceQuality.natural:
        return '';
      case VoiceQuality.basicNative:
      case VoiceQuality.phoneticFallback:
      case VoiceQuality.unavailable:
        if (kIsWeb) {
          return 'For the most natural voice, open this app in Microsoft Edge or Chrome and stay connected once so the natural “Online” voice for $_currentLanguage can load.';
        }
        if (defaultTargetPlatform == TargetPlatform.android) {
          return 'For a natural offline voice in $_currentLanguage, open Settings → System → Languages → Text-to-speech, pick “Google Speech Services”, then Install voice data for $_currentLanguage. It works fully offline afterwards.';
        }
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return 'For a natural offline voice in $_currentLanguage, open iPhone Settings → Accessibility → Spoken Content → Voices and download a $_currentLanguage voice. It then works offline.';
        }
        return 'Install a $_currentLanguage voice pack in your system Text-to-speech settings for the most natural offline voice.';
    }
  }

  Future<void> _initTts() async {
    if (_isInitialized) return;

    try {
      // Audio session configuration for iOS
      try {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.duckOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
        );
      } catch (_) {}

      // Await speech completion on native platforms so utterances do not truncate
      // Skipped on Web where Web Speech API can deadlock Future completion
      if (!kIsWeb) {
        try {
          await _tts.awaitSpeakCompletion(true);
        } catch (_) {}
      }

      // Android: prefer Google TTS high-quality engine if present
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          final engines = await _tts.getEngines;
          if (engines is List && engines.contains('com.google.android.tts')) {
            await _tts.setEngine('com.google.android.tts');
          }
        } catch (_) {}
      }

      await _tts.setVolume(_volume);
      await _applyPitch(_pitch);
      await _applySpeechRate(_speechRate);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _currentUtterance = null;
        notifyListeners();
        final cb = _onDoneCallback;
        _onDoneCallback = null;
        cb?.call();
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        _currentUtterance = null;
        _onDoneCallback = null;
        notifyListeners();
      });

      _tts.setErrorHandler((dynamic err) {
        debugPrint('VoiceEngine error: $err');
        _isSpeaking = false;
        _currentUtterance = null;
        _onDoneCallback = null;
        notifyListeners();
      });

      try {
        final voices = await _tts.getVoices;
        if (voices is List) {
          _availableVoices = voices;
        }
      } catch (_) {}

      _isInitialized = true;
      // Configure default language and optimal voice
      await setLanguage(_currentLanguage);
      notifyListeners();
    } catch (e) {
      debugPrint('VoiceEngine initialization error: $e');
    }
  }

  /// Platform-aware rate translation
  /// Normalized 1.0 corresponds to relaxed, soothing conversational pace for seniors.
  double _normalizeRateForPlatform(double userRate) {
    double normalized = userRate;
    // Migrate legacy stored values (< 0.70) to normalized 1.0 scale
    if (userRate <= 0.65) {
      normalized = (userRate / 0.50).clamp(0.75, 1.25);
    }
    normalized = normalized.clamp(0.70, 1.25);

    // Apply per-language pacing (some scripts/voices need a calmer, clearer pace
    // for an elder to follow comfortably). _langRateMul is <= 1.0.
    normalized *= _langRateMul;

    if (kIsWeb) {
      // In Microsoft Edge & Chrome Web Speech API, Microsoft Online (Natural) neural voices
      // run through Azure neural vocoders at 24kHz.
      // Playing at 1.0 delivers the 100% natural, pristine, soothing human inflection.
      // Keeping rate around 1.0 prevents local audio DSP pitch/time flutter.
      return normalized.clamp(0.82, 1.12);
    } else {
      // FlutterTTS Android/iOS/Windows native runner: ~0.44 provides calm, gentle speech.
      return (normalized * 0.44).clamp(0.30, 0.58);
    }
  }

  Future<void> _applySpeechRate(double rate) async {
    final platformRate = _normalizeRateForPlatform(rate);
    try {
      await _tts.setSpeechRate(platformRate);
    } catch (_) {}
  }

  Future<void> _applyPitch(double pitch) async {
    // Keep pitch bounded to natural vocal sweet spot (0.92 to 1.10)
    // On Web, preserve the neural vocoder by strictly keeping pitch at 1.0
    // to prevent the browser's local DSP pitch-shifter from adding synthetic robotic artifacts.
    final naturalPitch = (pitch + _langPitchAdd).clamp(0.92, 1.10);
    try {
      if (kIsWeb) {
        await _tts.setPitch(1.0);
      } else {
        await _tts.setPitch(naturalPitch);
      }
    } catch (_) {}
  }

  /// Configure preferred voice persona ('female' | 'male') with natural soothing acoustics
  Future<void> setPersona(String persona) async {
    final lower = persona.toLowerCase();
    _persona = lower.contains('male') && !lower.contains('fe') ? 'male' : 'female';
    // A gentle male companion reads a hair lower & slower; the warm female
    // companion sits at the natural sweet spot. Route through the shared
    // rate/pitch pipeline so per-language pacing is preserved.
    _pitch = _persona == 'male' ? 0.96 : 1.0;
    await _selectOptimalVoiceForCurrentLanguage();
    await _applySpeechRate(_speechRate);
    await _applyPitch(_pitch);
    notifyListeners();
  }

  /// Set speech rate (normalized 0.75 - 1.25)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _applySpeechRate(_speechRate);
    notifyListeners();
  }

  /// Set vocal pitch (natural 0.90 - 1.15)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _applyPitch(_pitch);
    notifyListeners();
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _tts.setVolume(_volume);
    } catch (_) {}
    notifyListeners();
  }

  /// Configure language and select the warmest, most natural voice
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    final locale = _resolveLocale(language);

    try {
      // Set language directly on TTS
      await _tts.setLanguage(locale);
    } catch (_) {
      try {
        final fallbackLocale = _resolveFallbackLocale(language);
        await _tts.setLanguage(fallbackLocale);
      } catch (_) {
        try {
          await _tts.setLanguage('en-IN');
        } catch (_) {}
      }
    }

    await _selectOptimalVoiceForCurrentLanguage();

    // If phonetic fallback was engaged, align TTS engine locale to Indian English companion
    if (_isUsingPhoneticFallback) {
      try {
        await _tts.setLanguage('en-IN');
      } catch (_) {}
    }

    // Resolve per-language pacing/warmth and re-apply so the newly chosen voice
    // speaks at an elder-comfortable, soothing pace for this specific language.
    _resolveLanguageProsody(language);
    await _applySpeechRate(_speechRate);
    await _applyPitch(_pitch);

    notifyListeners();
  }

  /// Resolves calm, clear per-language pacing + warmth tuned for elderly listeners.
  /// Dravidian and phonetic-fallback languages get a gentler pace so every
  /// syllable lands clearly. Values are conservative to stay natural, never robotic.
  void _resolveLanguageProsody(String language) {
    final l = language.toLowerCase();

    double rateMul = 1.0;
    double pitchAdd = 0.0;

    // Dravidian scripts: longer agglutinative words — slow a touch for clarity.
    if (l.contains('tamil') || l.contains('தமிழ்')) {
      rateMul = 0.94;
      pitchAdd = 0.01;
    } else if (l.contains('telugu') || l.contains('తెలుగు')) {
      rateMul = 0.94;
    } else if (l.contains('kannada') || l.contains('ಕನ್ನಡ')) {
      rateMul = 0.94;
    } else if (l.contains('malayalam') || l.contains('മലയാളം')) {
      rateMul = 0.92; // fastest-syllable-rate language — slow the most
    } else if (l.contains('hindi') ||
        l.contains('हिन्दी') ||
        l.contains('हिंदी') ||
        l.contains('marathi') ||
        l.contains('मराठी') ||
        l.contains('nepali') ||
        l.contains('नेपाली')) {
      rateMul = 0.97;
      pitchAdd = 0.01;
    } else if (l.contains('bengal') ||
        l.contains('বাংলা') ||
        l.contains('assam') ||
        l.contains('অসমীয়া')) {
      rateMul = 0.96;
    } else if (l.contains('gujarati') ||
        l.contains('ગુજરાતી') ||
        l.contains('punjabi') ||
        l.contains('ਪੰਜਾਬੀ') ||
        l.contains('odia') ||
        l.contains('oriya') ||
        l.contains('ଓଡ଼ିଆ')) {
      rateMul = 0.96;
    } else if (l.contains('english')) {
      rateMul = 1.0;
      pitchAdd = 0.01;
    }

    // When we can only speak via the Romanized Indian-English companion,
    // slow down noticeably: transliterated syllables need extra room to be clear.
    if (_isUsingPhoneticFallback) {
      rateMul = (rateMul * 0.90).clamp(0.80, 1.0);
    }

    _langRateMul = rateMul;
    _langPitchAdd = pitchAdd;
  }

  /// Checks whether a voice supports the target language natively.
  static bool _isVoiceCompatibleWithLanguage(
    String voiceLocale,
    String voiceName,
    String targetLanguage,
  ) {
    final vl = voiceLocale.toLowerCase().replaceAll('_', '-');
    final vn = voiceName.toLowerCase();
    final tl = targetLanguage.toLowerCase();

    if (tl.contains('english')) {
      return vl.startsWith('en') || vn.contains('english') || vn.contains('en-');
    }
    if (tl.contains('tamil') || tl.contains('தமிழ்')) {
      return vl.startsWith('ta') ||
          vn.contains('tamil') ||
          vn.contains('ta-') ||
          vn.contains('pallavi') ||
          vn.contains('valluvar');
    }
    if (tl.contains('telugu') || tl.contains('తెలుగు')) {
      return vl.startsWith('te') ||
          vn.contains('telugu') ||
          vn.contains('te-') ||
          vn.contains('shruti') ||
          vn.contains('mohan');
    }
    if (tl.contains('kannada') || tl.contains('ಕನ್ನಡ')) {
      return vl.startsWith('kn') ||
          vn.contains('kannada') ||
          vn.contains('kn-') ||
          vn.contains('sapna') ||
          vn.contains('gagan');
    }
    if (tl.contains('malayalam') || tl.contains('മലയാളം')) {
      return vl.startsWith('ml') ||
          vn.contains('malayalam') ||
          vn.contains('ml-') ||
          vn.contains('sobhana') ||
          vn.contains('midhun');
    }
    if (tl.contains('marathi') || tl.contains('मराठी')) {
      return vl.startsWith('mr') ||
          vn.contains('marathi') ||
          vn.contains('mr-') ||
          vn.contains('aarohi') ||
          vn.contains('manohar') ||
          vl.startsWith('hi'); // Hindi Devanagari voice compatibility
    }
    if (tl.contains('gujarati') || tl.contains('ગુજરાતી')) {
      return vl.startsWith('gu') ||
          vn.contains('gujarati') ||
          vn.contains('gu-') ||
          vn.contains('dhwani') ||
          vn.contains('niranjan');
    }
    if (tl.contains('punjabi') || tl.contains('ਪੰਜਾਬੀ')) {
      return vl.startsWith('pa') ||
          vn.contains('punjabi') ||
          vn.contains('pa-') ||
          vn.contains('raavi') ||
          vn.contains('gurmukhi');
    }
    if (tl.contains('odia') || tl.contains('oriya') || tl.contains('ଓଡ଼ିଆ')) {
      return vl.startsWith('or') ||
          vn.contains('odia') ||
          vn.contains('oriya') ||
          vl.startsWith('bn');
    }
    if (tl.contains('hindi') || tl.contains('हिन्दी') || tl.contains('हिंदी')) {
      return vl.startsWith('hi') ||
          vn.contains('hindi') ||
          vn.contains('hi-') ||
          vn.contains('swara') ||
          vn.contains('madhur') ||
          vn.contains('kalpana') ||
          vn.contains('hemant');
    }
    if (tl.contains('bengal') || tl.contains('বাংলা')) {
      return vl.startsWith('bn') ||
          vn.contains('bengali') ||
          vn.contains('bangla') ||
          vn.contains('bn-') ||
          vn.contains('tanishaa') ||
          vn.contains('bashkar');
    }
    if (tl.contains('assam') || tl.contains('অসমীয়া')) {
      // Direct Assamese or Bengali fallback (same script, highest phonetic closeness)
      return vl.startsWith('as') ||
          vn.contains('assamese') ||
          vl.startsWith('bn') ||
          vn.contains('bengali') ||
          vn.contains('bangla') ||
          vn.contains('tanishaa');
    }
    if (tl.contains('manipuri') || tl.contains('meitei') || tl.contains('মৈতৈ')) {
      return vl.startsWith('mni') ||
          vn.contains('manipuri') ||
          vl.startsWith('bn') ||
          vn.contains('bengali') ||
          vn.contains('tanishaa');
    }
    if (tl.contains('nepali') || tl.contains('नेपाली')) {
      return vl.startsWith('ne') ||
          vn.contains('nepali') ||
          vl.startsWith('hi') ||
          vn.contains('hindi') ||
          vn.contains('swara');
    }
    if (tl.contains('mizo')) {
      return vl.startsWith('lus') || vn.contains('mizo') || vl.startsWith('en');
    }
    return false;
  }

  /// Smart Voice Selector:
  /// Finds the highest-quality, warmest natural voice available on the device
  /// that matches the language and selected persona (female/male).
  Future<void> _selectOptimalVoiceForCurrentLanguage() async {
    // Helper to check if available voices catalog contains high-quality online neural voices
    // or voices compatible with the current target language.
    bool hasTargetOrNaturalVoices() {
      if (_availableVoices.isEmpty) return false;
      for (final raw in _availableVoices) {
        String name = '';
        String voiceLocale = '';
        if (raw is Map) {
          name = (raw['name'] ?? raw['voice'] ?? raw['voiceURI'] ?? '').toString();
          voiceLocale = (raw['locale'] ?? raw['lang'] ?? raw['language'] ?? '').toString();
        } else if (raw is String) {
          name = raw;
        }
        final nl = name.toLowerCase();
        final vl = voiceLocale.toLowerCase();
        if (nl.contains('natural') || nl.contains('online') || nl.contains('neural')) {
          return true;
        }
        if (_isVoiceCompatibleWithLanguage(vl, nl, _currentLanguage)) {
          return true;
        }
      }
      return false;
    }

    // On Web, Edge/Chrome asynchronously populates the speech synthesizer catalog.
    // The initial synchronous getVoices() only returns legacy Desktop SAPI voices (David/Mark/Zira).
    // If no natural/online or compatible voice is present yet, wait & poll getVoices.
    if (kIsWeb && !hasTargetOrNaturalVoices()) {
      for (int i = 0; i < 6; i++) {
        try {
          final v = await _tts.getVoices;
          if (v is List && v.isNotEmpty) {
            _availableVoices = v;
            if (hasTargetOrNaturalVoices()) break;
          }
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 180));
      }
    } else if (_availableVoices.isEmpty) {
      for (int i = 0; i < 3; i++) {
        try {
          final v = await _tts.getVoices;
          if (v is List && v.isNotEmpty) {
            _availableVoices = v;
            break;
          }
        } catch (_) {}
        if (kIsWeb) {
          await Future.delayed(const Duration(milliseconds: 120));
        }
      }
    }

    if (_availableVoices.isEmpty) return;

    final targetLocale = _resolveLocale(_currentLanguage);
    final targetLangPrefix =
        targetLocale.split(RegExp(r'[-_]')).first.toLowerCase();

    // 1. Search for native voices installed for this language
    final compatibleVoices = _availableVoices.where((raw) {
      String name = '';
      String voiceLocale = '';
      if (raw is Map) {
        name = (raw['name'] ?? raw['voice'] ?? raw['voiceURI'] ?? '').toString();
        voiceLocale = (raw['locale'] ?? raw['lang'] ?? raw['language'] ?? '').toString();
      } else if (raw is String) {
        name = raw;
      }
      return _isVoiceCompatibleWithLanguage(voiceLocale, name, _currentLanguage);
    }).toList();

    List<dynamic> candidateVoices;
    if (compatibleVoices.isNotEmpty) {
      _isUsingPhoneticFallback = false;
      candidateVoices = compatibleVoices;
    } else {
      // No native voice installed on device for this language.
      // Activate Indian English companion voice (en-IN) as phonetic fallback.
      _isUsingPhoneticFallback = true;
      debugPrint(
        'VoiceEngine: No native voice found for $_currentLanguage. Using Indian English phonetic companion.',
      );
      candidateVoices = _availableVoices;
    }

    Map<String, String>? bestVoice;
    int highestScore = -99999;

    for (final raw in candidateVoices) {
      String name = '';
      String voiceLocale = '';

      if (raw is Map) {
        name = (raw['name'] ?? raw['voice'] ?? raw['voiceURI'] ?? '').toString();
        voiceLocale = (raw['locale'] ?? raw['lang'] ?? raw['language'] ?? raw['code'] ?? '').toString();
      } else if (raw is String) {
        name = raw;
      }

      if (name.isEmpty) continue;

      int score = 0;
      final nameLower = name.toLowerCase();
      final localeLower = voiceLocale.toLowerCase().replaceAll('_', '-');

      // If native compatible voices exist, strictly exclude any English voice
      if (!_isUsingPhoneticFallback &&
          !_currentLanguage.toLowerCase().contains('english') &&
          (localeLower.startsWith('en') || nameLower.contains('english'))) {
        continue;
      }

      // 1. Strictly penalize and banish legacy robotic/SAPI desktop voices
      if (nameLower.contains('david') ||
          nameLower.contains('mark') ||
          nameLower.contains('zira') ||
          nameLower.contains('desktop') ||
          nameLower.contains('sapi')) {
        score -= 1000;
      }

      // 2. High bonus for modern high-definition neural / natural voices
      if (nameLower.contains('natural') ||
          nameLower.contains('neural') ||
          nameLower.contains('online') ||
          nameLower.contains('wavenet') ||
          nameLower.contains('journey') ||
          nameLower.contains('studio') ||
          nameLower.contains('enhanced') ||
          nameLower.contains('premium')) {
        score += 300;
      }

      // 3. Locale / Language Matching
      if (!_isUsingPhoneticFallback) {
        if (voiceLocale.isNotEmpty) {
          if (localeLower == targetLocale.toLowerCase().replaceAll('_', '-')) {
            score += 180;
          } else if (localeLower.startsWith(targetLangPrefix)) {
            score += 140;
          }
        }
      } else {
        // Fallback mode: prioritize warm Indian English neural companions
        if (nameLower.contains('neerja') ||
            nameLower.contains('prabhat') ||
            nameLower.contains('heera') ||
            nameLower.contains('swara') ||
            nameLower.contains('madhur')) {
          score += 250;
        } else if (localeLower.contains('en-in') || nameLower.contains('india')) {
          score += 180;
        } else if (localeLower.startsWith('en')) {
          score += 30;
        }
      }

      // 4. Strict Persona Matching (Soothing Female/Girl vs Gentle Male/Boy)
      final femaleKeywords = [
        'swara',
        'tanishaa',
        'kalpana',
        'heera',
        'neerja',
        'pallavi',
        'shruti',
        'sapna',
        'sobhana',
        'aarohi',
        'dhwani',
        'zira',
        'aria',
        'jenny',
        'sonia',
        'libby',
        'samantha',
        'lekha',
        'veena',
        'female',
        'woman',
        'girl',
        'kavya',
        'priya',
        'ananya',
        'maya',
        'aditi',
      ];
      final maleKeywords = [
        'madhur',
        'bashkar',
        'hemant',
        'valluvar',
        'mohan',
        'gagan',
        'midhun',
        'manohar',
        'niranjan',
        'raavi',
        'prabhat',
        'ravi',
        'rishi',
        'guy',
        'ryan',
        'male',
        'man',
        'boy',
        'david',
        'mark',
        'george',
        'daniel',
        'oliver',
        'james',
        'arjun',
        'rohit',
      ];

      final isFemaleVoice = femaleKeywords.any((kw) => nameLower.contains(kw));
      final isMaleVoice = maleKeywords.any((kw) => nameLower.contains(kw));

      if (_persona == 'female') {
        if (isFemaleVoice) score += 400;
        if (nameLower.contains('swara') ||
            nameLower.contains('tanishaa') ||
            nameLower.contains('kalpana') ||
            nameLower.contains('neerja') ||
            nameLower.contains('pallavi') ||
            nameLower.contains('shruti') ||
            nameLower.contains('sapna') ||
            nameLower.contains('sobhana') ||
            nameLower.contains('aarohi') ||
            nameLower.contains('dhwani') ||
            nameLower.contains('jenny') ||
            nameLower.contains('sonia') ||
            nameLower.contains('heera')) {
          score += 250;
        }
        // Heavily disqualify male voices when female persona is selected
        if (isMaleVoice) score -= 1000;
      } else if (_persona == 'male') {
        if (isMaleVoice) score += 400;
        if (nameLower.contains('madhur') ||
            nameLower.contains('bashkar') ||
            nameLower.contains('hemant') ||
            nameLower.contains('valluvar') ||
            nameLower.contains('mohan') ||
            nameLower.contains('gagan') ||
            nameLower.contains('midhun') ||
            nameLower.contains('manohar') ||
            nameLower.contains('niranjan') ||
            nameLower.contains('raavi') ||
            nameLower.contains('prabhat') ||
            nameLower.contains('ravi') ||
            nameLower.contains('guy') ||
            nameLower.contains('ryan') ||
            nameLower.contains('rishi')) {
          score += 250;
        }
        // Heavily disqualify female voices when male persona is selected
        if (isFemaleVoice) score -= 1000;
      }

      if (score > highestScore) {
        highestScore = score;
        bestVoice = {
          'name': name,
          'locale': voiceLocale.isNotEmpty
              ? voiceLocale
              : (_isUsingPhoneticFallback ? 'en-IN' : targetLocale),
        };
      }
    }

    if (bestVoice != null) {
      try {
        await _tts.setVoice(bestVoice);
        _activeVoice = bestVoice;
        if (bestVoice['locale'] != null && bestVoice['locale']!.isNotEmpty) {
          await _tts.setLanguage(bestVoice['locale']!);
        }
        debugPrint(
          'VoiceEngine: Activated soothing natural voice "${bestVoice['name']}" for $_currentLanguage (fallback: $_isUsingPhoneticFallback)',
        );
      } catch (e) {
        debugPrint('VoiceEngine: Could not setVoice: $e');
      }
    }
  }

  /// Primary locale resolution
  String _resolveLocale(String language) {
    final langInfo = AppTranslations.getLanguageInfo(language);
    return langInfo.ttsLocale;
  }

  /// Fallback locale in case OS does not ship specific smaller regional locale
  String _resolveFallbackLocale(String language) {
    final l = language.toLowerCase();
    if (l.contains('tamil') || l.contains('தமிழ்')) {
      return 'ta-IN';
    }
    if (l.contains('telugu') || l.contains('తెలుగు')) {
      return 'te-IN';
    }
    if (l.contains('kannada') || l.contains('ಕನ್ನಡ')) {
      return 'kn-IN';
    }
    if (l.contains('malayalam') || l.contains('മലയാളം')) {
      return 'ml-IN';
    }
    if (l.contains('marathi') || l.contains('मराठी')) {
      return 'hi-IN'; // Devanagari phonetic parity
    }
    if (l.contains('gujarati') || l.contains('ગુજરાતી')) {
      return 'hi-IN';
    }
    if (l.contains('punjabi') || l.contains('ਪੰਜਾਬੀ')) {
      return 'hi-IN';
    }
    if (l.contains('odia') || l.contains('oriya') || l.contains('ଓଡ଼ିଆ')) {
      return 'bn-IN';
    }
    if (l.contains('assam') ||
        l.contains('অসমীয়া') ||
        l.contains('manipuri') ||
        l.contains('মৈতৈ')) {
      return 'bn-IN'; // Bengali TTS provides phonetic parity for Assamese & Meitei
    }
    if (l.contains('nepali') || l.contains('नेपाली')) {
      return 'hi-IN'; // Hindi Devanagari phonology
    }
    if (l.contains('mizo')) {
      return 'en-IN'; // Mizo uses Latin alphabet with phonetic mapping
    }
    return 'en-IN';
  }

  /// Cleans raw conversational text of emojis, markdown, and tricky characters
  /// so text-to-speech sounds silky-smooth and conversational.
  static String cleanTextForSpeech(String input) {
    var text = input;

    // 1. Remove URLs
    text = text.replaceAll(RegExp(r'https?:\/\/\S+'), '');

    // 2. Remove Markdown bold, italic, headings, ticks
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m[1] ?? '');
    text = text.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m[1] ?? '');
    text = text.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m[1] ?? '');
    text = text.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m[1] ?? '');
    text = text.replaceAllMapped(RegExp(r'~~([^~]+)~~'), (m) => m[1] ?? '');
    text = text.replaceAll(RegExp(r'#{1,6}\s*'), '');
    text = text.replaceAll(RegExp(r'[`>]'), '');

    // 3. Strip all emojis and pictographs cleanly
    text = text.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1FA00}-\u{1FAFF}]|[\u{200D}]|[\u{FE0F}]',
        unicode: true,
      ),
      '',
    );

    // 4. Remove leading bullet dashes or bullets
    text = text.replaceAll(RegExp(r'^\s*[-•*]\s+', multiLine: true), '');

    // 5. Clean time representations (e.g. "8:00 AM" -> "8 AM")
    text = text.replaceAllMapped(
      RegExp(r'(\b\d{1,2}):00\s*(AM|PM|am|pm)\b'),
      (m) => '${m[1]} ${m[2]?.toUpperCase()}',
    );
    text = text.replaceAllMapped(
      RegExp(r'(\b\d{1,2}):(\d{2})\s*(AM|PM|am|pm)\b'),
      (m) => '${m[1]} ${m[2]} ${m[3]?.toUpperCase()}',
    );

    // 6. Conversational replacements
    text = text.replaceAll(RegExp(r'\bDr\.\s*'), 'Doctor ');
    text = text.replaceAll('&', ' and ');
    text = text.replaceAll('/', ' or ');

    // 7. Punctuation cleanup
    text = text.replaceAll(RegExp(r'["“”‘’]'), '');
    text = text.replaceAll(RegExp(r'--+'), ', ');
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text.trim();
  }

  /// Transforms text to add gentle cadence, tender breath pauses,
  /// and soothing listener inflection instead of rigid chatbot delivery.
  static String humanizeForSoothingSpeech(String input) {
    var text = cleanTextForSpeech(input);

    // 1. Soften abrupt exclamation points into gentle pauses.
    // In TTS, "!" causes loud, artificial, robotic volume spikes.
    // Changing to "." or "," creates a calm, soothing, tender tone.
    text = text.replaceAll(RegExp(r'!+'), '.');

    // 2. Insert natural listening pauses after greetings and salutations across all languages.
    // Use Unicode-safe boundary rather than ASCII \b so regional scripts match correctly.
    text = text.replaceAllMapped(
      RegExp(
        r'(?:^|(?<=[\s,.]))(Namaste|Hello|Hi|Good morning|Good afternoon|Good evening|Chibai|Khurumjari|নমস্কাৰ|নমস্কার|नमस्ते|வணக்கம்|நல்வரவு|నమస్కారం|స్వాగతం|ನಮಸ್ಕಾರ|ಸುಸ್ವಾಗತ|നമസ്കാരം|സ്വാഗതം|नमस्कार|स्वागत|નમસ્તે|સ્વાગત|ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ|ਜੀ ਆਇਆਂ ਨੂੰ|ନମସ୍କାର|ସ୍ୱାଗତ)\s*([,!]|\.{1,3})?\s*',
        caseSensitive: false,
        unicode: true,
      ),
      (m) => '${m[1]}... ',
    );

    // 3. Gentle pauses around loving vocatives in all languages
    text = text.replaceAllMapped(
      RegExp(
        r'(?:^|(?<=[\s,.]))(Amma|Appa|Dada|Dadi|Baba|Maa|Ma|Naniji|Dadaji|Thatha|Patti|Ka nu|Aama|আই|মা|ইমা|माँ|அம்மா|அப்பா|தாத்தா|பாட்டி|అమ్మ|నాన్న|తాతయ్య|బామ్మ|ಅಮ್ಮ|ಅಪ್ಪ|ಅಜ್ಜ|ಅಜ್ಜಿ|അമ്മ|അച്ഛൻ|മുത്തശ്ശൻ|മുത്തശ്ശി|आई|बाबा|आजी|आजोबा|બા|દાદા|દાદી|ਬੇਬੇ|ਬਾਪੂ|ମାଆ|ବାପା|ଜେଜେ)\s*([,!]|\.{1,3})?\s*',
        caseSensitive: false,
        unicode: true,
      ),
      (m) => '${m[1]}... ',
    );

    // 4. Soften conversational transitions so it feels like an unhurried, listening friend
    text = text.replaceAllMapped(
      RegExp(
        r'(?:^|(?<=[\s,.]))(Take your time|I am right here|Do you remember|Tell me|Of course|I understand|I hear you|No rush at all|மெதுவாக சொல்லுங்கள்|உங்களுடன் இருக்கிறேன்|சொல்லுங்கள்|చెప్పండి|హాయిగా చెప్పండి|ಹೇಳಿ|ತಾಳ್ಮೆಯಿಂದ ಹೇಳಿ|പറയൂ|सांगा|कहो|ਦੱਸੋ|କୁହନ୍ତୁ)\s*([,!]|\.{1,3})?\s*',
        caseSensitive: false,
        unicode: true,
      ),
      (m) => '${m[1]}... ',
    );

    // 5. Replace semicolons and em-dashes with soft breathing pauses
    text = text.replaceAll(RegExp(r'[\u2013\u2014;]'), ', ');

    // 6. Clean spacing around pauses and prevent runaway dots
    text = text.replaceAll(RegExp(r'\.{4,}'), '...');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    text = text.replaceAll(' ,', ',');
    text = text.replaceAll(' .', '.');

    return text.trim();
  }

  static final Map<String, String> _phrasePhoneticMap = {
    'খুরুমজরি, ইমা... ঐহাক নখোইগী সাথীনি। নখোইগী লোয়ননা লৈবদা য়াম্না নুংঙাই।': 'Khurumjari, Ema... Eihak nahakki Saathini. Nahakki loyanna leibada yamna nungai.',
    'Chibai, Ka nu... Kei hi i Saathi ka ni e. I kianga awm hi ka lawm hle mai.': 'Chibai, Ka nu... Kei hi i Saathi ka ni e. I kianga awm hi ka lawm hle mai.',
    'नमस्ते, आमा... म तपाईंको साथी स्मृति साथी हुँ। तपाईंसँग हुन पाउँदा मलाई धेरै खुसी लागेको छ।': 'Namaste, Aama... Ma tapaaiko saathi Smriti Saathi hoon. Tapaaisanga huna paaudaa malai dherai khusi laageko chha.',
    'Hello, Amma... I am your companion Saathi. I am right here with you.': 'Hello, Amma... I am your companion Saathi. I am right here with you.',
    'வணக்கம் மற்றும் நல்வரவு': 'Vanakkam matrum nalvaravu',
    'నమస్కారం మరియు స్వాగతం': 'Namaskaram mariyu swagatam',
    'ನಮಸ್ಕಾರ ಮತ್ತು ಸುಸ್ವಾಗತ': 'Namaskara mattu suswagatha',
    'നമസ്കാരം, സ്വാഗതം': 'Namaskaram, swagatham',
    'नमस्कार आणि आपले स्वागत आहे': 'Namaskar aani aple swagat aahe',
    'નમસ્તે અને સ્વાગત છે': 'Namaste ane swagat chhe',
    'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਅਤੇ ਜੀ ਆਇਆਂ ਨੂੰ': 'Sat sri akaal ate jee aayan nu',
    'ନମସ୍କାର ଏବଂ ସ୍ୱାଗତ': 'Namaskar ebang swagata',
    'নমস্কাৰ আৰু স্বাগতম': 'Nomoskar aaru swaagotom',
    'নমস্কার ও স্বাগতম': 'Nomoshkar o swaagotom',
    'नमस्ते और स्वागत है': 'Namaste aur swaagat hai',
    'খুরুমজরি অমসুং তরাম্না ওকচরি': 'Khurumjari amsung taramna okchari',
    'नमस्ते र स्वागत छ': 'Namaste ra swaagat chha',
    'Chibai leh lo kal rawh le': 'Chibai leh lo kal rawh le',
    'Hello & Welcome': 'Hello and Welcome',
    'ஸ்மிருதி சாதி': 'Smriti Saathi',
    'స్మృతి సాథి': 'Smriti Saathi',
    'ಸ್ಮೃತಿ ಸಾಥಿ': 'Smriti Saathi',
    'സ്മൃതി സാഥി': 'Smriti Saathi',
    'स्मृती साथी': 'Smriti Saathi',
    'સ્મૃતિ સાથી': 'Smriti Saathi',
    'ਸਮ੍ਰਿਤੀ ਸਾਥੀ': 'Smriti Saathi',
    'ସ୍ମୃତି ସାଥୀ': 'Smriti Saathi',
    'স্মৃতি সাথী': 'Smriti Saathi',
    'स्मृति साथी': 'Smriti Saathi',
  };

  /// Transliterates Indic script (Devanagari / Eastern Nagari) into smooth Romanized phonetics
  /// so an Indian English companion TTS voice can speak them naturally without silence or failure.
  static String romanizeIndicScript(String input, {String? language}) {
    final trimmed = input.trim();
    if (_phrasePhoneticMap.containsKey(trimmed)) {
      return _phrasePhoneticMap[trimmed]!;
    }
    for (final l in AppTranslations.supportedLanguages) {
      if (trimmed == l.greeting.trim() && l.phoneticGreeting.isNotEmpty) {
        return l.phoneticGreeting;
      }
    }

    final chars = input.runes.toList();
    final sb = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      final code = chars[i];
      final ch = String.fromCharCode(code);

      if (_isIndicConsonant(code)) {
        final romanConsonant = _indicConsonantToRoman(code);
        sb.write(romanConsonant);

        // Determine if inherent vowel should be appended
        final hasNext = i + 1 < chars.length;
        if (hasNext && _isIndicMatraOrVirama(chars[i + 1])) {
          // Next rune is a matra or virama; do not add inherent vowel
        } else {
          // Eastern Nagari (Bengali/Assamese) inherent vowel tends to 'o', Devanagari to 'a'
          final isEasternNagari = (code >= 0x0980 && code <= 0x09FF);
          sb.write(isEasternNagari ? 'o' : 'a');
        }
      } else if (_isVirama(code)) {
        // Virama silences inherent vowel; produces nothing in output
      } else if (_isIndicMatra(code)) {
        sb.write(_indicMatraToRoman(code));
      } else if (_isIndicIndependentVowel(code)) {
        sb.write(_indicVowelToRoman(code));
      } else if (_isIndicSign(code)) {
        sb.write(_indicSignToRoman(code));
      } else {
        sb.write(ch);
      }
    }

    var result = sb.toString();
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    return result;
  }

  static bool _isIndicConsonant(int code) {
    return (code >= 0x0915 && code <= 0x0939) ||
        (code >= 0x0958 && code <= 0x095F) ||
        (code >= 0x0995 && code <= 0x09B9) ||
        (code >= 0x09DC && code <= 0x09DF) ||
        code == 0x09F0 ||
        code == 0x09F1;
  }

  static bool _isIndicMatraOrVirama(int code) {
    return (code >= 0x093E && code <= 0x094D) ||
        (code >= 0x09BE && code <= 0x09CD);
  }

  static bool _isVirama(int code) => code == 0x094D || code == 0x09CD;

  static bool _isIndicMatra(int code) {
    return (code >= 0x093E && code <= 0x094C) ||
        (code >= 0x09BE && code <= 0x09CC);
  }

  static bool _isIndicIndependentVowel(int code) {
    return (code >= 0x0904 && code <= 0x0914) ||
        (code >= 0x0985 && code <= 0x0994);
  }

  static bool _isIndicSign(int code) {
    return code == 0x0901 ||
        code == 0x0902 ||
        code == 0x0903 ||
        code == 0x0981 ||
        code == 0x0982 ||
        code == 0x0983;
  }

  static String _indicConsonantToRoman(int code) {
    switch (code) {
      // Devanagari consonants
      case 0x0915: return 'k';
      case 0x0916: return 'kh';
      case 0x0917: return 'g';
      case 0x0918: return 'gh';
      case 0x0919: return 'ng';
      case 0x091A: return 'ch';
      case 0x091B: return 'chh';
      case 0x091C: return 'j';
      case 0x091D: return 'jh';
      case 0x091E: return 'ny';
      case 0x091F: return 't';
      case 0x0920: return 'th';
      case 0x0921: return 'd';
      case 0x0922: return 'dh';
      case 0x0923: return 'n';
      case 0x0924: return 't';
      case 0x0925: return 'th';
      case 0x0926: return 'd';
      case 0x0927: return 'dh';
      case 0x0928: return 'n';
      case 0x092A: return 'p';
      case 0x092B: return 'ph';
      case 0x092C: return 'b';
      case 0x092D: return 'bha';
      case 0x092E: return 'm';
      case 0x092F: return 'y';
      case 0x0930: return 'r';
      case 0x0932: return 'l';
      case 0x0935: return 'v';
      case 0x0936: return 'sh';
      case 0x0937: return 'sh';
      case 0x0938: return 's';
      case 0x0939: return 'h';
      case 0x0958: return 'q';
      case 0x0959: return 'kh';
      case 0x095A: return 'g';
      case 0x095B: return 'z';
      case 0x095C: return 'r';
      case 0x095D: return 'rh';
      case 0x095E: return 'f';

      // Eastern Nagari (Bengali & Assamese) consonants
      case 0x0995: return 'k';
      case 0x0996: return 'kh';
      case 0x0997: return 'g';
      case 0x0998: return 'gh';
      case 0x0999: return 'ng';
      case 0x099A: return 'ch';
      case 0x099B: return 'chh';
      case 0x099C: return 'j';
      case 0x099D: return 'jh';
      case 0x099E: return 'ny';
      case 0x099F: return 't';
      case 0x09A0: return 'th';
      case 0x09A1: return 'd';
      case 0x09A2: return 'dh';
      case 0x09A3: return 'n';
      case 0x09A4: return 't';
      case 0x09A5: return 'th';
      case 0x09A6: return 'd';
      case 0x09A7: return 'dh';
      case 0x09A8: return 'n';
      case 0x09AA: return 'p';
      case 0x09AB: return 'ph';
      case 0x09AC: return 'b';
      case 0x09AD: return 'bh';
      case 0x09AE: return 'm';
      case 0x09AF: return 'j';
      case 0x09B0: return 'r';
      case 0x09B2: return 'l';
      case 0x09B6: return 'sh';
      case 0x09B7: return 'sh';
      case 0x09B8: return 's';
      case 0x09B9: return 'h';
      case 0x09DC: return 'r';
      case 0x09DD: return 'rh';
      case 0x09DF: return 'y';
      case 0x09F0: return 'r'; // Assamese Ra
      case 0x09F1: return 'w'; // Assamese Wa
      default: return '';
    }
  }

  static String _indicMatraToRoman(int code) {
    switch (code) {
      // Devanagari Matras
      case 0x093E: return 'aa';
      case 0x093F: return 'i';
      case 0x0940: return 'ee';
      case 0x0941: return 'u';
      case 0x0942: return 'oo';
      case 0x0943: return 'ri';
      case 0x0947: return 'e';
      case 0x0948: return 'ai';
      case 0x094B: return 'o';
      case 0x094C: return 'au';

      // Bengali / Assamese Matras
      case 0x09BE: return 'aa';
      case 0x09BF: return 'i';
      case 0x09C0: return 'ee';
      case 0x09C1: return 'u';
      case 0x09C2: return 'oo';
      case 0x09C3: return 'ri';
      case 0x09C7: return 'e';
      case 0x09C8: return 'oi';
      case 0x09CB: return 'o';
      case 0x09CC: return 'ou';
      default: return '';
    }
  }

  static String _indicVowelToRoman(int code) {
    switch (code) {
      // Devanagari Vowels
      case 0x0905: return 'a';
      case 0x0906: return 'aa';
      case 0x0907: return 'i';
      case 0x0908: return 'ee';
      case 0x0909: return 'u';
      case 0x090A: return 'oo';
      case 0x090B: return 'ri';
      case 0x090F: return 'e';
      case 0x0910: return 'ai';
      case 0x0913: return 'o';
      case 0x0914: return 'au';

      // Eastern Nagari Vowels
      case 0x0985: return 'o';
      case 0x0986: return 'aa';
      case 0x0987: return 'i';
      case 0x0988: return 'ee';
      case 0x0989: return 'u';
      case 0x098A: return 'oo';
      case 0x098B: return 'ri';
      case 0x098F: return 'e';
      case 0x0990: return 'oi';
      case 0x0993: return 'o';
      case 0x0994: return 'ou';
      default: return '';
    }
  }

  static String _indicSignToRoman(int code) {
    switch (code) {
      case 0x0901:
      case 0x0902:
      case 0x0981:
      case 0x0982:
        return 'n';
      case 0x0903:
      case 0x0983:
        return 'h';
      default:
        return '';
    }
  }

  /// Speak text with automatic language resolution, soothing listener cadence, and senior-safe pauses
  Future<void> speak(
    String text, {
    String? language,
    double? rate,
    double? pitch,
    VoidCallback? onDone,
  }) async {
    _onDoneCallback = onDone;
    final targetLang = language ?? _currentLanguage;
    await setLanguage(targetLang);

    // If using phonetic fallback and the input has Indic script characters,
    // transliterate them to Romanized phonetic syllables so the Indian English TTS voice
    // can speak them smoothly without failing or remaining silent.
    var speechInput = text;
    if (_isUsingPhoneticFallback &&
        RegExp(r'[\u0900-\u09FF]').hasMatch(speechInput)) {
      speechInput = romanizeIndicScript(speechInput, language: targetLang);
    }

    final naturalText = humanizeForSoothingSpeech(speechInput);
    if (naturalText.isEmpty) {
      onDone?.call();
      return;
    }

    final effectiveRate = rate ?? _speechRate;
    await _applySpeechRate(effectiveRate);

    final effectivePitch = pitch ?? _pitch;
    await _applyPitch(effectivePitch);

    // ── Check if True Offline Neural Voice is available & ready ──
    final isNeuralReady =
        !kIsWeb && _neuralTts.isLanguageReady(targetLang, persona: _persona);

    if (isNeuralReady) {
      if (_isSpeaking) {
        await stop();
        await Future.delayed(const Duration(milliseconds: 40));
      }

      _isNeuralActive = true;
      _currentUtterance = naturalText;
      _isSpeaking = true;
      notifyListeners();

      // Neural VITS/Piper voices sound their warmest and most soothing a hair
      // below 1.0 — an unhurried, tender cadence for elderly listeners that
      // shaves off the clipped, "AI-generated" briskness without ever dragging.
      const neuralSoothingFactor = 0.94;

      final success = await _neuralTts.speak(
        naturalText,
        language: targetLang,
        persona: _persona,
        speed: (effectiveRate * _langRateMul * neuralSoothingFactor)
            .clamp(0.72, 1.15),
        onDone: () {
          _isSpeaking = false;
          _isNeuralActive = false;
          _currentUtterance = null;
          final cb = _onDoneCallback;
          _onDoneCallback = null;
          notifyListeners();
          cb?.call();
        },
      );

      if (success) {
        return;
      }
      // If neural synthesis failed, seamlessly fallback to flutter_tts
      _isNeuralActive = false;
    }

    try {
      // Clean buffer reset: stop previous utterance cleanly
      if (_isSpeaking) {
        try {
          await _tts.stop();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 50));
      }

      _isNeuralActive = false;
      _currentUtterance = naturalText;
      _isSpeaking = true;
      notifyListeners();

      await _tts.speak(naturalText);
    } catch (e) {
      debugPrint('VoiceEngine speak error: $e');
      _isSpeaking = false;
      _isNeuralActive = false;
      _currentUtterance = null;
      _onDoneCallback = null;
      notifyListeners();
    }
  }

  /// Stop any ongoing speech playback cleanly
  Future<void> stop() async {
    _onDoneCallback = null;
    await _neuralTts.stop();
    try {
      await _tts.stop();
    } catch (_) {}
    _isSpeaking = false;
    _isNeuralActive = false;
    _currentUtterance = null;
    notifyListeners();
  }

  /// Play a friendly test utterance in the specified language with current rate and pitch
  Future<void> testVoice({String? language, double? rate, double? pitch}) async {
    final lang = language ?? _currentLanguage;
    final text = _getTestGreeting(lang);
    await speak(
      text,
      language: lang,
      rate: rate ?? _speechRate,
      pitch: pitch ?? _pitch,
    );
  }

  String _getTestGreeting(String language) {
    final langInfo = AppTranslations.getLanguageInfo(language);
    if (_isUsingPhoneticFallback && langInfo.phoneticGreeting.isNotEmpty) {
      return langInfo.phoneticGreeting;
    }
    return langInfo.greeting;
  }
}
