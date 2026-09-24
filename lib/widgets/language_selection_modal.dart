import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_translations.dart';
import '../services/tts/voice_model_manager.dart';
import '../services/tts/voice_model_registry.dart';
import '../services/voice_engine.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import 'animated_scale_button.dart';

class LanguageSelectionModal extends StatefulWidget {
  final bool isDismissible;
  final ValueChanged<String>? onLanguageConfirmed;

  const LanguageSelectionModal({
    super.key,
    this.isDismissible = true,
    this.onLanguageConfirmed,
  });

  static Future<String?> show(
    BuildContext context, {
    bool isDismissible = true,
    ValueChanged<String>? onLanguageConfirmed,
  }) {
    // Ultra-premium centered glassmorphic reveal with blurred backdrop & smooth slide/fade exit
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: 'Language selection',
      barrierColor: const Color(0xFF0F2E22).withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, _, __) {
        final size = MediaQuery.of(context).size;
        final isWide = size.width > 600;
        return SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 24 : 16,
                vertical: isWide ? 24 : 18,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: size.height * (isWide ? 0.86 : 0.84),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: LanguageSelectionModal(
                    isDismissible: isDismissible,
                    onLanguageConfirmed: onLanguageConfirmed,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        final isClosing = anim.status == AnimationStatus.reverse;
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        final fade = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 14 * fade.value,
            sigmaY: 14 * fade.value,
          ),
          child: FadeTransition(
            opacity: fade,
            child: Transform.translate(
              // On closing: slides smoothly down completely off the screen with proper fade off!
              offset: Offset(0, isClosing ? (1 - fade.value) * 650 : (1 - fade.value) * 28),
              child: Transform.scale(
                scale: isClosing
                    ? 0.94 + 0.06 * fade.value
                    : 0.90 + curved.value.clamp(0.0, 1.2) * 0.10,
                alignment: Alignment.center,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<LanguageSelectionModal> createState() => _LanguageSelectionModalState();
}

class _LanguageSelectionModalState extends State<LanguageSelectionModal>
    with TickerProviderStateMixin {
  late String _selectedLanguage;
  String? _currentlySpeaking;
  bool _isPreparingVoice = false;

  late final AnimationController _entrance; // staggered card rise
  late final AnimationController _breathe; // header badge levitation
  late final AnimationController _dismissSlide; // interactive swipe-down & desktop click dismissal

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

  String _getLanguageCode(LanguageInfo lang) {
    final lower = lang.englishName.toLowerCase();
    if (lower.contains('english')) return 'EN';
    if (lower.contains('tamil')) return 'TA';
    if (lower.contains('hindi')) return 'HI';
    if (lower.contains('telugu')) return 'TE';
    if (lower.contains('kannada')) return 'KN';
    if (lower.contains('malayalam')) return 'ML';
    if (lower.contains('marathi')) return 'MR';
    if (lower.contains('bengali')) return 'BN';
    if (lower.contains('gujarati')) return 'GU';
    if (lower.contains('punjabi')) return 'PA';
    if (lower.contains('odia')) return 'OR';
    if (lower.contains('assamese')) return 'AS';
    if (lower.contains('manipuri')) return 'MN';
    if (lower.contains('mizo')) return 'MZ';
    if (lower.contains('nepali')) return 'NE';
    final prefix = lang.ttsLocale.split(RegExp(r'[-_]')).first.toUpperCase();
    return prefix.length > 2 ? prefix.substring(0, 2) : prefix;
  }

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );
    _breathe = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);
    _dismissSlide = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context);
    _selectedLanguage = settings.language;
  }

  @override
  void dispose() {
    _entrance.dispose();
    _breathe.dispose();
    _dismissSlide.dispose();
    VoiceEngine().stop();
    super.dispose();
  }

  /// Interactive swipe down tracking
  void _onHandleDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta != null && (details.primaryDelta! > 0 || _dismissSlide.value > 0)) {
      _dismissSlide.value = (_dismissSlide.value + details.primaryDelta! / 400.0).clamp(0.0, 1.0);
    }
  }

  void _onHandleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dismissSlide.value > 0.16 || velocity > 320) {
      _dismissWithAnimation();
    } else {
      _dismissSlide.animateTo(
        0.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
      );
    }
  }

  /// Proper smooth slide down and fade off animation
  void _dismissWithAnimation() {
    VoiceEngine().stop();
    _dismissSlide.animateTo(
      1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInCubic,
    ).then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  /// Staggered fade + rise for the Nth card with cached child
  Widget _riseCard(int index, Widget child) {
    final start = (index * 0.05).clamp(0.0, 0.55);
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, cachedChild) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 16),
          child: cachedChild,
        ),
      ),
    );
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

      // Align voice engine with chosen language
      await VoiceEngine().setLanguage(lang.englishName);

      // If OS lacks native regional voice, use natural phonetic greeting with Indian English companion
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
          VoiceModelManager().downloadModel(model).then((success) {
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

  void _executeConfirm() {
    VoiceEngine().stop();
    final settings = AppSettingsScope.of(context);
    settings.setLanguage(_selectedLanguage);
    settings.setHasSelectedLanguage(true);
    widget.onLanguageConfirmed?.call(_selectedLanguage);
    Navigator.of(context).pop(_selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final translation = AppTranslations.get(_selectedLanguage);
    final languages = AppTranslations.supportedLanguages;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _dismissSlide,
      builder: (context, child) {
        final progress = _dismissSlide.value;
        // Smoothly fade out the entire modal as it slides down
        final opacity = (1.0 - progress * 1.05).clamp(0.0, 1.0);
        // Translate the entire modal downwards completely off screen
        final translateY = progress * (screenHeight * 0.85 + 100);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              // Translucent frosted glass wash
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.94),
                  const Color(0xFFF9FBF8).withValues(alpha: 0.88),
                  const Color(0xFFEFF7EE).withValues(alpha: 0.94),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4332).withValues(alpha: 0.22),
                  blurRadius: 42,
                  offset: const Offset(0, 16),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.7),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Upper Draggable Surface: Drag Handle Bar + Header + Divider
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: _onHandleDragUpdate,
                    onVerticalDragEnd: _onHandleDragEnd,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sleek Drag Handle Bar (Draggable on mobile, Clickable on desktop)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: Row(
                            children: [
                              // Symmetrical left spacer if (X) exists on desktop
                              SizedBox(width: isMobile ? 0 : 38),

                              // Center Interactive Handle Bar
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    // Touching that bar in desktop closes the modal with slide down & fade off
                                    if (!isMobile) {
                                      _dismissWithAnimation();
                                    }
                                  },
                                  child: MouseRegion(
                                    cursor: isMobile
                                        ? SystemMouseCursors.grab
                                        : SystemMouseCursors.click,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      alignment: Alignment.center,
                                      child: Container(
                                        width: isMobile ? 48 : 56,
                                        height: 5.5,
                                        decoration: BoxDecoration(
                                          color: AppTheme.forest.withValues(alpha: 0.28),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withValues(alpha: 0.85),
                                              offset: const Offset(0, 1),
                                              blurRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Right Button: strictly REMOVED in mobile! Available on desktop only.
                              if (!isMobile && widget.isDismissible)
                                AnimatedScaleButton(
                                  onTap: _dismissWithAnimation,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.deepForest
                                              .withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: AppTheme.deepForest,
                                    ),
                                  ),
                                )
                              else
                                SizedBox(width: isMobile ? 0 : 38),
                            ],
                          ),
                        ),

                        // Compact space-efficient header (frees up vertical room for language list)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Compact title row with subtle breathing icon
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _breathe,
                                    builder: (context, child) {
                                      final b = _breathe.value;
                                      return Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF2D6A4F),
                                              Color(0xFF1B4332),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.forest.withValues(alpha: 0.22 + 0.1 * b),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.translate_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 9),
                                  Flexible(
                                    child: Text(
                                      translation.modalTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.comfortaa(
                                        fontSize: 18.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.deepForest,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Crisp, legible edition badge pill (guaranteed overflow-safe)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.forest.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.forest.withValues(alpha: 0.18),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.eco_rounded,
                                      size: 13,
                                      color: AppTheme.forest,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 250),
                                        child: Text(
                                          translation.editionBadge,
                                          key: ValueKey<String>(translation.editionBadge),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTranslations.getFont(
                                            _selectedLanguage,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.forest,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Delicate glass divider
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.forest.withValues(alpha: 0.0),
                                AppTheme.forest.withValues(alpha: 0.12),
                                AppTheme.forest.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Language cards + floating confirm bar with overscroll pull-down dismiss
                  Expanded(
                    child: Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification notification) {
                            if (notification is ScrollUpdateNotification) {
                              if (notification.metrics.pixels <= 0 &&
                                  notification.scrollDelta != null &&
                                  notification.scrollDelta! < 0) {
                                _dismissSlide.value =
                                    (_dismissSlide.value - notification.scrollDelta! / 400.0).clamp(0.0, 1.0);
                              }
                            } else if (notification is OverscrollNotification) {
                              if (notification.overscroll < 0) {
                                _dismissSlide.value =
                                    (_dismissSlide.value - notification.overscroll / 400.0).clamp(0.0, 1.0);
                              }
                            } else if (notification is ScrollEndNotification) {
                              if (_dismissSlide.value > 0) {
                                if (_dismissSlide.value > 0.16 ||
                                    (notification.dragDetails?.primaryVelocity ?? 0) > 320) {
                                  _dismissWithAnimation();
                                } else {
                                  _dismissSlide.animateTo(
                                    0.0,
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeOutBack,
                                  );
                                }
                              }
                            }
                            return false;
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: languages.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 11),
                            itemBuilder: (context, index) =>
                                _riseCard(index, _buildLanguageCard(languages[index])),
                          ),
                        ),
                        _buildConfirmBar(translation),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Floating Frosted Glass Action Bar ──
  Widget _buildConfirmBar(dynamic translation) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.78),
                  Colors.white.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
            ),
            child: _isPreparingVoice
                ? _buildVoiceDownloadProgress(translation)
                : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AnimatedScaleButton(
                      onTap: _confirmSelection,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2D6A4F),
                              Color(0xFF1B4332),
                              Color(0xFF0F2E22),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.forest.withValues(alpha: 0.42),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, -1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              translation.confirmButton,
                              style: AppTranslations.getFont(
                                _selectedLanguage,
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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

    return AnimatedBuilder(
      animation: VoiceModelManager(),
      builder: (context, _) {
        final progress = model != null
            ? VoiceModelManager().getProgress(model.id)
            : 0.0;
        final percent = (progress * 100).toInt();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.forest.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppTheme.forest,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Preparing natural voice… $percent%',
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepForest,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _executeConfirm,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: Text(
                      'Continue anyway →',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.forest,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  minHeight: 5,
                  backgroundColor: AppTheme.forest.withValues(alpha: 0.12),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.forest),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Glassmorphic Language Card ──
  Widget _buildLanguageCard(LanguageInfo lang) {
    final isSelected = _selectedLanguage == lang.id ||
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
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
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
                    Colors.white.withValues(alpha: 0.78),
                    Colors.white.withValues(alpha: 0.58),
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
                    color: accent.withValues(alpha: 0.24),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _buildBadge(accent, langCode, isSelected, isSpeaking),
              const SizedBox(width: 13),
              Expanded(child: _buildCardInfo(lang, accent, isSelected, isSpeaking)),
              const SizedBox(width: 10),
              _buildRadio(accent, isSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
      Color accent, String langCode, bool isSelected, bool isSpeaking) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isSelected ? 0.22 : 0.09),
            accent.withValues(alpha: isSelected ? 0.10 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isSelected ? 0.55 : 0.18),
          width: 1.3,
        ),
      ),
      alignment: Alignment.center,
      child: isSpeaking
          ? Icon(Icons.graphic_eq_rounded, color: accent, size: 24)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  langCode,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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
    );
  }

  Widget _buildCardInfo(
      LanguageInfo lang, Color accent, bool isSelected, bool isSpeaking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                lang.nativeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTranslations.getFont(
                  lang.englishName,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
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
        GestureDetector(
          onTap: () => _playGreeting(lang),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: isSpeaking
                  ? accent.withValues(alpha: 0.16)
                  : (isSelected
                      ? accent.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.8)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSpeaking
                    ? accent.withValues(alpha: 0.4)
                    : (isSelected
                        ? accent.withValues(alpha: 0.2)
                        : Colors.white),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSpeaking
                      ? Icons.volume_up_rounded
                      : Icons.play_circle_outline_rounded,
                  size: 13,
                  color: isSpeaking ? accent : AppTheme.muted,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    lang.greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTranslations.getFont(
                      lang.englishName,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isSpeaking
                          ? accent
                          : AppTheme.muted.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadio(Color accent, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent,
                  Color.lerp(accent, Colors.black, 0.15)!,
                ],
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        border: Border.all(
          color: isSelected ? accent : const Color(0xFFCBD5E1),
          width: 1.8,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.42),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : null,
    );
  }
}
