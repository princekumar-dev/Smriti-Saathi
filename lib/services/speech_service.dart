import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Senior-Friendly Speech-to-Text Engine
/// Handles multilingual acoustic input, patient pause thresholds, and live feedback
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isAvailable = false;
  String _lastError = '';
  List<stt.LocaleName> _locales = [];
  double _soundLevel = 0.0;

  bool get isInitialized => _isInitialized;
  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;
  String get lastError => _lastError;
  double get soundLevel => _soundLevel;
  List<stt.LocaleName> get supportedLocales => _locales;

  /// Initialize speech engine and load available locale packages
  Future<bool> initialize({
    Function(String status)? onStatus,
    Function(SpeechRecognitionError error)? onError,
  }) async {
    if (_isInitialized) return _isAvailable;

    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          onStatus?.call(status);
        },
        onError: (errorNotification) {
          debugPrint('Speech error: ${errorNotification.errorMsg}');
          _lastError = errorNotification.errorMsg;
          onError?.call(errorNotification);
        },
        debugLogging: kDebugMode,
      );

      if (_isAvailable) {
        try {
          _locales = await _speech.locales();
        } catch (_) {}
      }

      _isInitialized = true;
      return _isAvailable;
    } catch (e) {
      debugPrint('Error initializing speech_to_text: $e');
      _isAvailable = false;
      _lastError = e.toString();
      return false;
    }
  }

  /// Resolves the optimal speech recognition locale for a given language
  String resolveSttLocale(String language) {
    final l = language.toLowerCase();
    String targetCode = 'en_IN';

    if (l.contains('hindi') || l.contains('हिंदी') || l.contains('हिन्दी')) {
      targetCode = 'hi_IN';
    } else if (l.contains('bengal') || l.contains('বাংলা')) {
      targetCode = 'bn_IN';
    } else if (l.contains('assam') || l.contains('অসমীয়া')) {
      targetCode = 'as_IN';
    } else if (l.contains('nepal') || l.contains('नेपाली')) {
      targetCode = 'ne_NP';
    } else if (l.contains('manipuri') || l.contains('meitei') || l.contains('মৈতৈ')) {
      targetCode = 'mni_IN';
    } else if (l.contains('mizo')) {
      targetCode = 'en_IN';
    }

    // Check if the exact locale exists on device; otherwise pick best matching fallback
    if (_locales.isNotEmpty) {
      final exactMatch = _locales.any((loc) =>
          loc.localeId.toLowerCase().replaceAll('-', '_') ==
          targetCode.toLowerCase().replaceAll('-', '_'));
      if (exactMatch) return targetCode;

      // Fallback: match by 2-letter language code
      final prefix = targetCode.split('_').first;
      for (final loc in _locales) {
        if (loc.localeId.toLowerCase().startsWith(prefix)) {
          return loc.localeId;
        }
      }

      // If Assamese/Manipuri is not present, Bengali has closest acoustic models
      if (targetCode == 'as_IN' || targetCode == 'mni_IN') {
        for (final loc in _locales) {
          if (loc.localeId.toLowerCase().startsWith('bn')) {
            return loc.localeId;
          }
        }
      }

      // Fallback to Hindi or English for Indian English accents
      for (final loc in _locales) {
        if (loc.localeId.contains('en_IN') || loc.localeId.contains('en-IN')) {
          return loc.localeId;
        }
      }
    }

    return targetCode;
  }

  /// Start listening for voice input with senior-patient timeout parameters
  Future<bool> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(String status)? onStatus,
    Function(SpeechRecognitionError error)? onError,
    Function(double level)? onSoundLevelChange,
    String? language,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize(onStatus: onStatus, onError: onError);
      if (!ok) {
        debugPrint('Speech recognition could not be initialized');
        return false;
      }
    }

    if (_speech.isListening) {
      await stopListening();
    }

    final resolvedLocale = localeId ?? (language != null ? resolveSttLocale(language) : 'en_IN');

    try {
      return await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        onSoundLevelChange: (level) {
          _soundLevel = level;
          onSoundLevelChange?.call(level);
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          localeId: resolvedLocale,
          // Senior-patient duration: 3.5 seconds pause before cutting off, up to 40 seconds listen
          pauseFor: const Duration(milliseconds: 3500),
          listenFor: const Duration(seconds: 40),
        ),
      );
    } catch (e) {
      debugPrint('Error starting speech listen: $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (e) {
      debugPrint('Error canceling speech: $e');
    }
  }
}
