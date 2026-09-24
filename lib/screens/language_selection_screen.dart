import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_translations.dart';
import '../services/tts/voice_model_manager.dart';
import '../services/tts/voice_model_registry.dart';
import '../services/voice_engine.dart';
import '../state/app_settings.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/fx/fade_slide_in.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final VoidCallback? onLanguageConfirmed;

  const LanguageSelectionScreen({
    super.key,
    this.onLanguageConfirmed,
  });

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with TickerProviderStateMixin {
  late String _selectedLanguage;
  String? _currentlySpeaking;
  late final AnimationController _breathe;
  late final AnimationController _shimmer;
  bool _isPreparingVoice = false;
  bool _voiceReadyPreviewing = false;

  static const Map<String, Color> _langAccents = {
    'English': Color(0xFF1B6B4A),
    'தமிழ்': Color(0xFFC04128),
    'Tamil': Color(0xFFC04128),
    'हिन्दी': Color(0xFF24608B),
    'Hindi': Color(0xFF24608B),
    'తెలుగు': Color(0xFFB85D19),
    'Telugu': Color(0xFFB85D19),
    'ಕನ್ನಡ': Color(0xFF7A3E9D),
    'Kannada': Color(0xFF7A3E9D),
    'മലയാളം': Color(0xFF167C6F),
    'Malayalam': Color(0xFF167C6F),
    'मराठी': Color(0xFFC2612D),
    'Marathi': Color(0xFFC2612D),
    'বাংলা': Color(0xFF9E3A5A),
    'Bengali': Color(0xFF9E3A5A),
    'ગુજરાતી': Color(0xFF386B94),
    'Gujarati': Color(0xFF386B94),
    'ਪੰਜਾਬੀ': Color(0xFFAD5424),
    'Punjabi': Color(0xFFAD5424),
    'ଓଡ଼ିଆ': Color(0xFF5B679E),
    'Odia': Color(0xFF5B679E),
    'অসমীয়া': Color(0xFF3B7B66),
    'Assamese': Color(0xFF3B7B66),
    'মৈতৈলোন্': Color(0xFF8A4B82),
    'Manipuri': Color(0xFF8A4B82),
    'Mizo': Color(0xFF2D7B8E),
    'नेपाली': Color(0xFF9C4932),
    'Nepali': Color(0xFF9C4932),
  };

  Color _getLangAccent(LanguageInfo lang) {
    return _langAccents[lang.id] ??
        _langAccents[lang.englishName] ??
        _langAccents[lang.nativeName] ??
        AppTheme.forest;
  }

  /// Localized copy for the on-demand neural voice download, keyed by English
  /// language name. Falls back to English when a translation is missing.
  static const Map<String, List<String>> _voiceCopy = {
    // [ download CTA, preparing message, offline hint ]
    'English': [
      'Download Voice & Continue',
      'Preparing your natural voice',
      'Works fully offline afterwards',
    ],
    'Hindi': [
      'आवाज़ डाउनलोड करें और आगे बढ़ें',
      'आपकी प्राकृतिक आवाज़ तैयार हो रही है',
      'इसके बाद पूरी तरह ऑफ़लाइन काम करेगा',
    ],
    'Tamil': [
      'குரலைப் பதிவிறக்கி தொடரவும்',
      'உங்கள் இயற்கை குரல் தயாராகிறது',
      'பின்னர் முழுவதும் ஆஃப்லைனில் இயங்கும்',
    ],
    'Telugu': [
      'వాయిస్ డౌన్‌లోడ్ చేసి కొనసాగించండి',
      'మీ సహజ వాయిస్ సిద్ధమవుతోంది',
      'ఆ తర్వాత పూర్తిగా ఆఫ్‌లైన్‌లో పనిచేస్తుంది',
    ],
    'Kannada': [
      'ಧ್ವನಿ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ ಮುಂದುವರಿಯಿರಿ',
      'ನಿಮ್ಮ ಸಹಜ ಧ್ವನಿ ಸಿದ್ಧವಾಗುತ್ತಿದೆ',
      'ನಂತರ ಸಂಪೂರ್ಣ ಆಫ್‌ಲೈನ್‌ನಲ್ಲಿ ಕಾರ್ಯನಿರ್ವಹಿಸುತ್ತದೆ',
    ],
    'Malayalam': [
      'ശബ്ദം ഡൗൺലോഡ് ചെയ്ത് തുടരുക',
      'നിങ്ങളുടെ സ്വാഭാവിക ശബ്ദം തയ്യാറാകുന്നു',
      'പിന്നീട് പൂർണ്ണമായും ഓഫ്‌ലൈനിൽ പ്രവർത്തിക്കും',
    ],
    'Marathi': [
      'आवाज डाउनलोड करा आणि पुढे जा',
      'तुमचा नैसर्गिक आवाज तयार होत आहे',
      'त्यानंतर पूर्णपणे ऑफलाइन चालेल',
    ],
    'Bengali': [
      'ভয়েস ডাউনলোড করে এগিয়ে যান',
      'আপনার প্রাকৃতিক কণ্ঠ প্রস্তুত হচ্ছে',
      'এরপর সম্পূর্ণ অফলাইনে কাজ করবে',
    ],
    'Gujarati': [
      'અવાજ ડાઉનલોડ કરો અને આગળ વધો',
      'તમારો કુદરતી અવાજ તૈયાર થઈ રહ્યો છે',
      'ત્યારબાદ સંપૂર્ણ ઓફલાઇન કામ કરશે',
    ],
    'Punjabi': [
      'ਆਵਾਜ਼ ਡਾਊਨਲੋਡ ਕਰੋ ਅਤੇ ਅੱਗੇ ਵਧੋ',
      'ਤੁਹਾਡੀ ਕੁਦਰਤੀ ਆਵਾਜ਼ ਤਿਆਰ ਹੋ ਰਹੀ ਹੈ',
      'ਇਸ ਤੋਂ ਬਾਅਦ ਪੂਰੀ ਤਰ੍ਹਾਂ ਆਫ਼ਲਾਈਨ ਕੰਮ ਕਰੇਗਾ',
    ],
    'Odia': [
      'ସ୍ୱର ଡାଉନଲୋଡ୍ କରି ଆଗକୁ ବଢ଼ନ୍ତୁ',
      'ଆପଣଙ୍କ ପ୍ରାକୃତିକ ସ୍ୱର ପ୍ରସ୍ତୁତ ହେଉଛି',
      'ପରେ ସମ୍ପୂର୍ଣ୍ଣ ଅଫଲାଇନ୍‌ରେ କାମ କରିବ',
    ],
    'Assamese': [
      'ধ্বনি ডাউনলোড কৰি আগবাঢ়ক',
      'আপোনাৰ প্ৰাকৃতিক কণ্ঠ প্ৰস্তুত হৈ আছে',
      'ইয়াৰ পিছত সম্পূৰ্ণ অফলাইনত কাম কৰিব',
    ],
    'Nepali': [
      'आवाज डाउनलोड गरी अगाडि बढ्नुहोस्',
      'तपाईंको प्राकृतिक आवाज तयार हुँदैछ',
      'त्यसपछि पूर्ण रूपमा अफलाइन चल्नेछ',
    ],
  };

  List<String> _voiceStrings() {
    final english = AppTranslations.getLanguageInfo(_selectedLanguage).englishName;
    return _voiceCopy[english] ?? _voiceCopy['English']!;
  }

  /// True when the selected language has a neural voice pack that is not yet
  /// downloaded — used to swap the CTA to a download-aware label.
  bool _needsVoiceDownload() {
    if (kIsWeb) return false;
    final settings = AppSettingsScope.of(context);
    final model = VoiceModelRegistry.getModelFor(
      language: _selectedLanguage,
      persona: settings.voicePersona,
    );
    return model != null &&
        model.isNeuralAvailable &&
        !VoiceModelManager().isReady(model.id);
  }

  String _getLanguageCode(LanguageInfo lang) {
    final prefix = lang.ttsLocale.split(RegExp(r'[-_]')).first.toUpperCase();
    if (prefix == 'EN') return 'EN';
    if (prefix == 'TA') return 'TA';
    if (prefix == 'HI') return 'HI';
    if (prefix == 'TE') return 'TE';
    if (prefix == 'KN') return 'KN';
    if (prefix == 'ML') return 'ML';
    if (prefix == 'MR') return 'MR';
    if (prefix == 'BN') return 'BN';
    if (prefix == 'GU') return 'GU';
    if (prefix == 'PA') return 'PA';
    if (prefix == 'OR') return 'OR';
    if (prefix == 'AS') return 'AS';
    if (prefix == 'MNI') return 'MN';
    if (lang.englishName.toLowerCase().contains('mizo')) return 'MZ';
    if (prefix == 'NE') return 'NE';
    return prefix.length > 2 ? prefix.substring(0, 2) : prefix;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context);
    _selectedLanguage = settings.language;
  }

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _breathe.dispose();
    _shimmer.dispose();
    VoiceEngine().stop();
    super.dispose();
  }

  void _playGreeting(LanguageInfo lang) async {
    try {
      if (_currentlySpeaking == lang.id) {
        await VoiceEngine().stop();
        if (mounted) setState(() => _currentlySpeaking = null);
        return;
      }
      setState(() => _currentlySpeaking = lang.id);
      final settings = AppSettingsScope.of(context);

      await VoiceEngine().setLanguage(lang.englishName);

      final textToSpeak =
          (VoiceEngine().isUsingPhoneticFallback && lang.phoneticGreeting.isNotEmpty)
              ? lang.phoneticGreeting
              : lang.greeting;

      await VoiceEngine().speak(
        textToSpeak,
        language: lang.englishName,
        rate: settings.voiceRate,
        pitch: settings.voicePitch,
        onDone: () {
          if (mounted) setState(() => _currentlySpeaking = null);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _currentlySpeaking = null);
    }
  }

  void _confirmSelection() {
    VoiceEngine().stop();
    final settings = AppSettingsScope.of(context);

    // On non-web: check if high-fidelity neural voice model needs downloading
    if (!kIsWeb) {
      final model = VoiceModelRegistry.getModelFor(
        language: _selectedLanguage,
        persona: settings.voicePersona,
      );

      if (model != null &&
          model.isNeuralAvailable &&
          !VoiceModelManager().isReady(model.id)) {
        if (!_isPreparingVoice) {
          setState(() => _isPreparingVoice = true);
          VoiceModelManager().downloadModel(model).then((success) async {
            if (!mounted || !_isPreparingVoice) return;
            // Let the senior hear the exact offline voice they just downloaded —
            // the confirmation greeting now plays through the real neural model,
            // so the "initial sound" matches what will speak to them from here on.
            if (success) {
              await _previewDownloadedNeuralVoice();
            }
            if (mounted && _isPreparingVoice) {
              _executeConfirm();
            }
          });
          return;
        }
      }
    }

    _executeConfirm();
  }

  /// After the neural pack lands, greet the user once in that freshly-downloaded
  /// offline voice so the preview and the installed voice are one and the same.
  /// Completes when the greeting finishes, with a safety cap so the flow never
  /// stalls if playback is unavailable.
  Future<void> _previewDownloadedNeuralVoice() async {
    try {
      final lang = AppTranslations.getLanguageInfo(_selectedLanguage);
      if (mounted) setState(() => _voiceReadyPreviewing = true);

      await VoiceEngine().setLanguage(lang.englishName);
      final textToSpeak = (VoiceEngine().isUsingPhoneticFallback &&
              lang.phoneticGreeting.isNotEmpty)
          ? lang.phoneticGreeting
          : lang.greeting;

      final completer = Completer<void>();
      VoiceEngine().speak(
        textToSpeak,
        language: lang.englishName,
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () {},
      );
    } catch (_) {
      // Playback issues must never block advancing to the next screen.
    } finally {
      if (mounted) setState(() => _voiceReadyPreviewing = false);
    }
  }

  void _executeConfirm() {
    VoiceEngine().stop();
    final settings = AppSettingsScope.of(context);
    settings.setLanguage(_selectedLanguage);
    settings.setHasSelectedLanguage(true);

    if (widget.onLanguageConfirmed != null) {
      widget.onLanguageConfirmed!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final translation = AppTranslations.get(_selectedLanguage);
    final languages = AppTranslations.supportedLanguages;
    final isTabletOrDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EA),
      body: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: constraints.maxHeight.isInfinite
              ? MediaQuery.of(context).size.height
              : constraints.maxHeight,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFDFBF4),
                  Color(0xFFF6F3EA),
                  Color(0xFFEFF5EC),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
            children: [
              // Centered premium header with breathing globe
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _breathe,
                      builder: (context, child) {
                        final b = _breathe.value;
                        return SizedBox(
                          width: 82,
                          height: 82,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 66 + b * 12,
                                height: 66 + b * 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.forest
                                      .withValues(alpha: 0.10 * (1 - b)),
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(0, -2 * b),
                                child: child,
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AppTheme.emeraldGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.forest.withValues(alpha: 0.32),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.translate_rounded,
                            color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      translation.modalTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comfortaa(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepForest,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      translation.modalSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.forest.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.spa_rounded,
                                size: 13, color: AppTheme.forest),
                            const SizedBox(width: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                translation.editionBadge,
                                key: ValueKey<String>(translation.editionBadge),
                                style: AppTranslations.getFont(
                                  _selectedLanguage,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.forest,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                  height: 1,
                  color: AppTheme.forest.withValues(alpha: 0.08)),

              // Language Grid / List
            Expanded(
              child: isTabletOrDesktop
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: languages.length,
                      itemBuilder: (context, index) => FadeSlideIn(
                        delay: AppMotion.staggerDelay(index, stepMs: 45, maxMs: 400),
                        child: _buildLanguageCard(languages[index]),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: languages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => FadeSlideIn(
                        delay: AppMotion.staggerDelay(index, stepMs: 45, maxMs: 400),
                        child: _buildLanguageCard(languages[index]),
                      ),
                    ),
            ),
          ],
        ),
        ),
        ),
        ),
      ),

      // Floating Bottom Confirmation Action
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFEFF5EC).withValues(alpha: 0.0),
              const Color(0xFFEFF5EC).withValues(alpha: 0.95),
              const Color(0xFFEFF5EC),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: _isPreparingVoice
              ? _buildVoiceDownloadProgress(translation)
              : AnimatedBuilder(
                  animation: VoiceModelManager(),
                  builder: (context, _) {
                    final needsDownload = _needsVoiceDownload();
                    final label = needsDownload
                        ? _voiceStrings()[0]
                        : translation.confirmButton;
                    return SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: AnimatedScaleButton(
                        onTap: _confirmSelection,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.emeraldGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.forest.withValues(alpha: 0.38),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (needsDownload) ...[
                                const Icon(Icons.download_rounded,
                                    size: 20, color: Colors.white),
                                const SizedBox(width: 10),
                              ],
                              Flexible(
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTranslations.getFont(
                                    _selectedLanguage,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildVoiceDownloadProgress(dynamic translation) {
    final settings = AppSettingsScope.of(context);
    final model = VoiceModelRegistry.getModelFor(
      language: _selectedLanguage,
      persona: settings.voicePersona,
    );
    final copy = _voiceStrings();
    final preparingMsg = copy[1];
    final offlineHint = copy[2];

    return AnimatedBuilder(
      animation: Listenable.merge([VoiceModelManager(), _shimmer]),
      builder: (context, _) {
        final progress = model != null
            ? VoiceModelManager().getProgress(model.id)
            : 0.0;
        final percent = (progress * 100).toInt();
        final previewing = _voiceReadyPreviewing;

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          decoration: BoxDecoration(
            gradient: AppTheme.glassCardGradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.forest.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.forest.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppTheme.emeraldSoftGradient,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      previewing
                          ? Icons.volume_up_rounded
                          : Icons.graphic_eq_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          previewing
                              ? '${AppTranslations.getLanguageInfo(_selectedLanguage).greeting} 🎙'
                              : '$preparingMsg… $percent%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTranslations.getFont(
                            _selectedLanguage,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.deepForest,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${model?.sizeLabel ?? "~65 MB"} · $offlineHint',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTranslations.getFont(
                            _selectedLanguage,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAnimatedProgressBar(previewing ? 1.0 : progress),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _executeConfirm,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    '${translation.continueButton} →',
                    style: AppTranslations.getFont(
                      _selectedLanguage,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.forest,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Progress bar filled with the brand's three-stop emerald gradient, with a
  /// soft highlight that continuously sweeps across the filled portion.
  Widget _buildAnimatedProgressBar(double progress) {
    // Show a gentle indeterminate crawl before the first byte lands.
    final fraction = progress <= 0.0 ? 0.06 : progress.clamp(0.02, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullWidth = constraints.maxWidth;
          final fillWidth = fullWidth * fraction;
          final sweep = _shimmer.value; // 0..1
          return Container(
            height: 9,
            width: fullWidth,
            color: AppTheme.forest.withValues(alpha: 0.12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: fillWidth,
                height: 9,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Base three-stop brand gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.premiumGradient,
                      ),
                    ),
                    // Moving highlight sweep
                    Positioned(
                      left: (fillWidth + 60) * sweep - 60,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.45),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Soft, living equalizer shown in a language's badge while its greeting
  /// plays — five bars breathing out of phase for a calm, soothing pulse
  /// rather than a flat static icon.
  Widget _buildEqualizer(Color accent) {
    const bars = 5;
    const phases = [0.0, 0.55, 0.2, 0.8, 0.35];
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(bars, (i) {
            final t = (_shimmer.value + phases[i]) % 1.0;
            // Smooth 0→1→0 swell via a sine wave for gentle, organic motion.
            final swell = 0.5 - 0.5 * math.cos(t * 2 * math.pi);
            final height = 6.0 + swell * 16.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.6),
              child: Container(
                width: 3.2,
                height: height,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.55 + swell * 0.45),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLanguageCard(LanguageInfo lang) {    final isSelected = _selectedLanguage == lang.id ||
        _selectedLanguage == lang.nativeName ||
        _selectedLanguage == lang.englishName;
    final isSpeaking = _currentlySpeaking == lang.id;
    final accent = _getLangAccent(lang);
    final langCode = _getLanguageCode(lang);

    return AnimatedScaleButton(
      onTap: () {
        setState(() => _selectedLanguage = lang.id);
        _playGreeting(lang);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.94),
                    accent.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.88),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.82),
                    Colors.white.withValues(alpha: 0.65),
                  ],
                ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.95),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF1B4332).withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Modern Premium Language Badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: isSelected ? 0.16 : 0.08),
                      accent.withValues(alpha: isSelected ? 0.08 : 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: accent.withValues(alpha: isSelected ? 0.35 : 0.14),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: isSpeaking
                    ? _buildEqualizer(accent)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            langCode,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: isSelected ? accent : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 14,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: isSelected ? accent : accent.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 14),

              // Language Names & Voice Preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Native Name + English Name
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            lang.nativeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTranslations.getFont(
                              lang.englishName,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? accent : AppTheme.deepForest,
                            ),
                          ),
                        ),
                        if (lang.nativeName != lang.englishName) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.12)
                                  : const Color(0xFF1B4332).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lang.englishName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? accent : AppTheme.muted,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Voice preview pill
                    GestureDetector(
                      onTap: () => _playGreeting(lang),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSpeaking
                              ? accent.withValues(alpha: 0.12)
                              : (isSelected
                                  ? accent.withValues(alpha: 0.08)
                                  : const Color(0xFFF3F5F4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSpeaking
                                  ? Icons.volume_up_rounded
                                  : Icons.play_circle_outline_rounded,
                              size: 14,
                              color: isSpeaking ? accent : AppTheme.muted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                lang.greeting,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTranslations.getFont(
                                  lang.englishName,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSpeaking
                                      ? accent
                                      : AppTheme.muted.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Modern Checkmark / Radio
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? accent : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
