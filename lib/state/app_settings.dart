import 'package:flutter/material.dart';

/// App-wide preferences that affect readability and comfort.
class AppSettings extends ChangeNotifier {
  AppSettings();

  bool _largeText = true;
  bool _voiceResponses = true;
  bool _offlineMode = true;
  bool _notifications = true;
  String _language = 'English';

  bool get largeText => _largeText;
  bool get voiceResponses => _voiceResponses;
  bool get offlineMode => _offlineMode;
  bool get notifications => _notifications;
  String get language => _language;

  double get textScale => _largeText ? 1.12 : 1.0;

  void setLargeText(bool value) {
    _largeText = value;
    notifyListeners();
  }

  void setVoiceResponses(bool value) {
    _voiceResponses = value;
    notifyListeners();
  }

  void setOfflineMode(bool value) {
    _offlineMode = value;
    notifyListeners();
  }

  void setNotifications(bool value) {
    _notifications = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    _language = value;
    notifyListeners();
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
