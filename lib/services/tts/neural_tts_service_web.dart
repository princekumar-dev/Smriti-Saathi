import 'dart:async';
import 'package:flutter/foundation.dart';

/// Web Stub for NeuralTtsService.
/// On Flutter Web, native FFI / sherpa_onnx is not used to prevent heavy WASM memory penalties.
/// Web seamlessly delegates to browser-native Online Natural voices via flutter_tts.
class NeuralTtsService {
  static final NeuralTtsService _instance = NeuralTtsService._internal();
  factory NeuralTtsService() => _instance;
  NeuralTtsService._internal();

  bool get isSupported => false;
  bool get isSpeaking => false;
  String? get currentVoiceId => null;

  Future<void> init() async {}

  bool isLanguageReady(String language, {String persona = 'female'}) => false;

  Future<bool> speak(
    String text, {
    required String language,
    String persona = 'female',
    double speed = 1.0,
    VoidCallback? onDone,
  }) async {
    return false;
  }

  Future<void> stop() async {}

  Future<void> dispose() async {}
}
