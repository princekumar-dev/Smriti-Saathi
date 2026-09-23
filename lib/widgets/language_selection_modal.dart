import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_translations.dart';
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
    final isTabletOrDesktop = MediaQuery.of(context).size.width > 600;

    if (isTabletOrDesktop) {
      return showDialog<String>(
        context: context,
        barrierDismissible: isDismissible,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 730),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: LanguageSelectionModal(
                isDismissible: isDismissible,
                onLanguageConfirmed: onLanguageConfirmed,
              ),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet<String>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.90,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: LanguageSelectionModal(
            isDismissible: isDismissible,
            onLanguageConfirmed: onLanguageConfirmed,
          ),
        ),
      ),
    );
  }

  @override
  State<LanguageSelectionModal> createState() => _LanguageSelectionModalState();
}

class _LanguageSelectionModalState extends State<LanguageSelectionModal> {
  late String _selectedLanguage;
  String? _currentlySpeaking;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context);
    _selectedLanguage = settings.language;
  }

  @override
  void dispose() {
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
    settings.setLanguage(_selectedLanguage);
    settings.setHasSelectedLanguage(true);
    widget.onLanguageConfirmed?.call(_selectedLanguage);
    Navigator.of(context).pop(_selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final translation = AppTranslations.get(_selectedLanguage);
    final languages = AppTranslations.supportedLanguages;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cream,
        boxShadow: [
          BoxShadow(
            color: Color(0x28184E77),
            blurRadius: 32,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Drag Handle & Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  const SizedBox(width: 36),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: AppTheme.forest.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  if (widget.isDismissible)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: AppTheme.muted,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        VoiceEngine().stop();
                        Navigator.of(context).pop();
                      },
                    )
                  else
                    const SizedBox(width: 36),
                ],
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
              child: Column(
                children: [
                  // Circular Globe Icon Badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppTheme.emeraldGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.forest.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Modern, Clean Title (Outfit typography - no stroke glitches)
                  Text(
                    translation.modalTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF184E77),
                      letterSpacing: -0.3,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Subtitle
                  Text(
                    translation.modalSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.muted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // North-Eastern India & National Trust Tag
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: AppTheme.sage.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.forest.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 13,
                            color: AppTheme.forest,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'North-East India & National Edition',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.forest,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0x18184E77)),

            // Language Cards List with Floating Bottom Bar Overlay
            Expanded(
              child: Stack(
                children: [
                  // Scrollable Language Cards List
                  ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 92),
                    physics: const BouncingScrollPhysics(),
                    itemCount: languages.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final lang = languages[index];
                      final isSelected = _selectedLanguage == lang.id ||
                          _selectedLanguage == lang.nativeName ||
                          _selectedLanguage == lang.englishName;
                      final isSpeaking = _currentlySpeaking == lang.id;
                      final accent = _getLangAccent(lang);
                      final langCode = _getLanguageCode(lang);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            setState(() => _selectedLanguage = lang.id);
                            _playGreeting(lang);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? accent : const Color(0xFFE5E9E7),
                                width: isSelected ? 1.8 : 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.15),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  // Modern Language Badge (No broken first letter)
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          accent.withValues(alpha: isSelected ? 0.16 : 0.08),
                                          accent.withValues(alpha: isSelected ? 0.08 : 0.03),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: accent.withValues(alpha: isSelected ? 0.35 : 0.14),
                                        width: 1.2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: isSpeaking
                                        ? Icon(
                                            Icons.graphic_eq_rounded,
                                            color: accent,
                                            size: 24,
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                langCode,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  color: isSelected ? accent : const Color(0xFF334155),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                width: 12,
                                                height: 2.2,
                                                decoration: BoxDecoration(
                                                  color: isSelected ? accent : accent.withValues(alpha: 0.35),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Language info & voice preview
                                  Expanded(
                                    child: Column(
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
                                                  fontSize: 16.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: isSelected ? accent : AppTheme.deepForest,
                                                ),
                                              ),
                                            ),
                                            if (lang.nativeName != lang.englishName) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '•  ${lang.englishName}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.muted,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // Voice pill
                                        GestureDetector(
                                          onTap: () => _playGreeting(lang),
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: isSpeaking
                                                  ? accent.withValues(alpha: 0.12)
                                                  : (isSelected
                                                      ? accent.withValues(alpha: 0.08)
                                                      : const Color(0xFFF3F5F4)),
                                              borderRadius: BorderRadius.circular(7),
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
                                                      fontWeight: FontWeight.w500,
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
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Checkmark radio
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? accent : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? accent : const Color(0xFFCBD5E1),
                                        width: 1.8,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: accent.withValues(alpha: 0.35),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 15,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Floating Seamless Bottom Scrim with Button (No white box cutoff!)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.cream.withValues(alpha: 0.0),
                            AppTheme.cream.withValues(alpha: 0.92),
                            AppTheme.cream,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: AnimatedScaleButton(
                          onTap: _confirmSelection,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.emeraldGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.forest.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
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
                                    fontWeight: FontWeight.w800,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
