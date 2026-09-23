import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_translations.dart';
import '../services/voice_engine.dart';

/// App-wide preferences that affect readability and comfort.
class AppSettings extends ChangeNotifier {
  AppSettings() {
    _loadFromPrefs();
  }

  static const String _kLanguageKey = 'smirithi_language';
  static const String _kHasSelectedLanguageKey = 'smirithi_has_selected_language';
  static const String _kLargeTextKey = 'smirithi_large_text';
  static const String _kVoiceResponsesKey = 'smirithi_voice_responses';
  static const String _kOfflineModeKey = 'smirithi_offline_mode';
  static const String _kNotificationsKey = 'smirithi_notifications';
  static const String _kVoiceRateKey = 'smirithi_voice_rate';
  static const String _kVoicePitchKey = 'smirithi_voice_pitch';
  static const String _kVoicePersonaKey = 'smirithi_voice_persona';

  bool _largeText = true;
  bool _voiceResponses = true;
  bool _offlineMode = true;
  bool _notifications = true;
  String _language = 'English';
  bool _hasSelectedLanguage = false;
  double _voiceRate = 1.0; // Calm natural senior pace
  double _voicePitch = 1.0; // Natural warm default
  String _voicePersona = 'female'; // 'female' (Warm Companion) | 'male' (Gentle Companion)

  bool get largeText => _largeText;
  bool get voiceResponses => _voiceResponses;
  bool get offlineMode => _offlineMode;
  bool get notifications => _notifications;
  String get language => _language;
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  double get voiceRate => _voiceRate;
  double get voicePitch => _voicePitch;
  String get voicePersona => _voicePersona;

  double get textScale => _largeText ? 1.12 : 1.0;

  String get ttsLocale => AppTranslations.getLanguageInfo(_language).ttsLocale;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _language = prefs.getString(_kLanguageKey) ?? 'English';
      _hasSelectedLanguage = prefs.getBool(_kHasSelectedLanguageKey) ?? false;
      _largeText = prefs.getBool(_kLargeTextKey) ?? true;
      _voiceResponses = prefs.getBool(_kVoiceResponsesKey) ?? true;
      _offlineMode = prefs.getBool(_kOfflineModeKey) ?? true;
      _notifications = prefs.getBool(_kNotificationsKey) ?? true;

      // Rate migration: convert old 0.46 scale to normalized 1.0 scale
      final rawRate = prefs.getDouble(_kVoiceRateKey);
      if (rawRate != null) {
        if (rawRate <= 0.65) {
          _voiceRate = (rawRate / 0.50).clamp(0.75, 1.25);
        } else {
          _voiceRate = rawRate.clamp(0.75, 1.25);
        }
      } else {
        _voiceRate = 1.0;
      }

      _voicePitch = (prefs.getDouble(_kVoicePitchKey) ?? 1.0).clamp(0.90, 1.15);
      _voicePersona = prefs.getString(_kVoicePersonaKey) ?? 'female';

      // Synchronize with VoiceEngine
      VoiceEngine().setSpeechRate(_voiceRate);
      VoiceEngine().setPitch(_voicePitch);
      VoiceEngine().setPersona(_voicePersona);
      VoiceEngine().setLanguage(_language);

      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLargeText(bool value) async {
    _largeText = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kLargeTextKey, value);
    } catch (_) {}
  }

  Future<void> setVoiceResponses(bool value) async {
    _voiceResponses = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kVoiceResponsesKey, value);
    } catch (_) {}
  }

  Future<void> setOfflineMode(bool value) async {
    _offlineMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOfflineModeKey, value);
    } catch (_) {}
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kNotificationsKey, value);
    } catch (_) {}
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    _hasSelectedLanguage = true;
    VoiceEngine().setLanguage(value);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguageKey, value);
      await prefs.setBool(_kHasSelectedLanguageKey, true);
    } catch (_) {}
  }

  Future<void> setHasSelectedLanguage(bool value) async {
    _hasSelectedLanguage = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHasSelectedLanguageKey, value);
    } catch (_) {}
  }

  Future<void> setVoicePersona(String value) async {
    _voicePersona = value;
    VoiceEngine().setPersona(value);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kVoicePersonaKey, value);
    } catch (_) {}
  }

  /// Automatically adapt companion voice based on senior's gender
  Future<void> autoSyncWithGender(String? gender) async {
    if (gender == null || gender.trim().isEmpty) return;
    final g = gender.toLowerCase();
    if (g.contains('female') || g.contains('woman') || g.contains('girl')) {
      if (_voicePersona != 'female') {
        await setVoicePersona('female');
      }
    } else if (g.contains('male') || g.contains('man') || g.contains('boy')) {
      if (_voicePersona != 'male') {
        await setVoicePersona('male');
      }
    }
  }

  Future<void> setVoiceRate(double value) async {
    _voiceRate = value.clamp(0.75, 1.25);
    VoiceEngine().setSpeechRate(_voiceRate);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kVoiceRateKey, _voiceRate);
    } catch (_) {}
  }

  Future<void> setVoicePitch(double value) async {
    _voicePitch = value.clamp(0.90, 1.15);
    VoiceEngine().setPitch(_voicePitch);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kVoicePitchKey, _voicePitch);
    } catch (_) {}
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found');
    return scope!.notifier!;
  }
}
