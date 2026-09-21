import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Robust Speech-to-Text service with automatic initialization, status reporting, and safe fallback
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isAvailable = false;
  String _lastError = '';

  bool get isInitialized => _isInitialized;
  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;
  String get lastError => _lastError;

  /// Initialize speech engine
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
      _isInitialized = true;
      return _isAvailable;
    } catch (e) {
      debugPrint('Error initializing speech_to_text: $e');
      _isAvailable = false;
      _lastError = e.toString();
      return false;
    }
  }

  /// Start listening for microphone input
  Future<bool> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(String status)? onStatus,
    Function(SpeechRecognitionError error)? onError,
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

    try {
      return await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          localeId: localeId,
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
