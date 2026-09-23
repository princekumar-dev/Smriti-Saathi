import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_translations.dart';
import '../services/voice_engine.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import 'onboarding_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final VoidCallback? onLanguageConfirmed;

  const LanguageSelectionScreen({
    super.key,
    this.onLanguageConfirmed,
  });

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
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
    settings.setLanguage(_selectedLanguage);
    settings.setHasSelectedLanguage(true);

    if (widget.onLanguageConfirmed != null) {
      widget.onLanguageConfirmed!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final translation = AppTranslations.get(_selectedLanguage);
    final languages = AppTranslations.supportedLanguages;
    final isTabletOrDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: const BoxDecoration(
                color: AppTheme.paper,
                border: Border(
                  bottom: BorderSide(color: AppTheme.divider, width: 1.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.paleSage,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.forest.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: AppTheme.forest,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translation.modalTitle,
                          style: AppTranslations.getFont(
                            _selectedLanguage,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.deepForest,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          translation.modalSubtitle,
                          style: AppTranslations.getFont(
                            _selectedLanguage,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                      itemBuilder: (context, index) => _buildLanguageCard(languages[index]),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: languages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildLanguageCard(languages[index]),
                    ),
            ),
          ],
        ),
      ),

      // Floating Bottom Confirmation Action
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
        decoration: BoxDecoration(
          color: AppTheme.paper,
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepForest.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppTheme.divider, width: 1.2),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _confirmSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forest,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    translation.confirmButton,
                    style: AppTranslations.getFont(
                      _selectedLanguage,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : const Color(0xFFE5E9E7),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
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
                    ? Icon(
                        Icons.graphic_eq_rounded,
                        color: accent,
                        size: 26,
                      )
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
                          Text(
                            '•  ${lang.englishName}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.muted,
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
