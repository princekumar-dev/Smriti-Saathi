import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'voice_model_manager.dart';
import 'voice_model_registry.dart';

class NeuralTtsService {
  static final NeuralTtsService _instance = NeuralTtsService._internal();
  factory NeuralTtsService() => _instance;
  NeuralTtsService._internal();

  sherpa.OfflineTts? _tts;
  String? _currentVoiceId;
  AudioPlayer? _player;
  bool _isSpeaking = false;
  bool _bindingsReady = false;
  VoidCallback? _onDoneCallback;
  StreamSubscription? _playerCompleteSubscription;

  bool get isSupported => true;
  bool get isSpeaking => _isSpeaking;
  String? get currentVoiceId => _currentVoiceId;

  Future<void> init() async {
    // sherpa_onnx needs its native FFI bindings loaded once (per isolate)
    // before any runtime object (OfflineTts) can be constructed.
    if (!_bindingsReady) {
      try {
        sherpa.initBindings();
        _bindingsReady = true;
      } catch (e) {
        debugPrint('[NeuralTtsService] initBindings failed: $e');
      }
    }
    _player ??= AudioPlayer();
    _playerCompleteSubscription ??=
        _player!.onPlayerComplete.listen((_) {
      _isSpeaking = false;
      _onDoneCallback?.call();
      _onDoneCallback = null;
    });
  }

  /// Check if the voice model for this language is ready
  bool isLanguageReady(String language, {String persona = 'female'}) {
    final entry = VoiceModelRegistry.getModelFor(
      language: language,
      persona: persona,
    );
    if (entry == null || !entry.isNeuralAvailable) return false;
    return VoiceModelManager().isReady(entry.id);
  }

  /// Load the offline neural model into memory if not already active
  Future<bool> _ensureModelLoaded(VoiceModelEntry entry) async {
    if (_tts != null && _currentVoiceId == entry.id) {
      return true;
    }

    try {
      final dir = await VoiceModelManager().getModelDirectory(entry);
      if (dir == null || !await dir.exists()) return false;

      final modelPath = '${dir.path}/model.onnx';
      final tokensPath = '${dir.path}/tokens.txt';
      final dataDirPath = entry.hasDataDir ? '${dir.path}/espeak-ng-data' : '';

      final vitsConfig = sherpa.OfflineTtsVitsModelConfig(
        model: modelPath,
        tokens: tokensPath,
        dataDir: dataDirPath,
      );

      final modelConfig = sherpa.OfflineTtsModelConfig(
        vits: vitsConfig,
        numThreads: 2,
        debug: false,
        provider: 'cpu',
      );

      final config = sherpa.OfflineTtsConfig(
        model: modelConfig,
      );

      _tts?.free();
      _tts = sherpa.OfflineTts(config);
      _currentVoiceId = entry.id;
      debugPrint('[NeuralTtsService] Loaded neural model: ${entry.id}');
      return true;
    } catch (e) {
      debugPrint('[NeuralTtsService] Failed to load model ${entry.id}: $e');
      _tts = null;
      _currentVoiceId = null;
      return false;
    }
  }

  /// Synthesize text and play audio locally
  Future<bool> speak(
    String text, {
    required String language,
    String persona = 'female',
    double speed = 1.0,
    VoidCallback? onDone,
  }) async {
    await init();
    await stop();

    final entry = VoiceModelRegistry.getModelFor(
      language: language,
      persona: persona,
    );
    if (entry == null || !entry.isNeuralAvailable) return false;

    final loaded = await _ensureModelLoaded(entry);
    if (!loaded || _tts == null) return false;

    _onDoneCallback = onDone;
    _isSpeaking = true;

    try {
      final audio = _tts!.generate(
        text: text,
        sid: 0,
        speed: speed.clamp(0.5, 2.0),
      );

      if (audio.samples.isEmpty) {
        _isSpeaking = false;
        onDone?.call();
        return false;
      }

      // Encode samples into a 16-bit PCM WAV byte array
      final wavBytes = _createWavBytes(
        audio.samples,
        sampleRate: audio.sampleRate,
      );

      await _player!.play(BytesSource(wavBytes));
      return true;
    } catch (e) {
      debugPrint('[NeuralTtsService] Speech synthesis/playback error: $e');
      _isSpeaking = false;
      onDone?.call();
      return false;
    }
  }

  /// Stop current playback
  Future<void> stop() async {
    _isSpeaking = false;
    _onDoneCallback = null;
    await _player?.stop();
  }

  /// Helper: converts float samples to 16-bit PCM WAV file format
  Uint8List _createWavBytes(Float32List samples, {required int sampleRate}) {
    final numSamples = samples.length;
    final byteRate = sampleRate * 1 * 2; // 1 channel, 16-bit (2 bytes)
    final blockAlign = 1 * 2;
    final dataSize = numSamples * 2;
    final totalSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);

    // RIFF chunk descriptor
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, totalSize, Endian.little);
    buffer.setUint8(8, 0x57); // 'W'
    buffer.setUint8(9, 0x41); // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // "fmt " sub-chunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    buffer.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    buffer.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, blockAlign, Endian.little);
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample

    // "data" sub-chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      // Clamp float -1.0 to 1.0 into 16-bit integer (-32768 to 32767)
      final sample = (samples[i].clamp(-1.0, 1.0) * 32767.0).toInt();
      buffer.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  Future<void> dispose() async {
    await stop();
    await _playerCompleteSubscription?.cancel();
    _playerCompleteSubscription = null;
    await _player?.dispose();
    _player = null;
    _tts?.free();
    _tts = null;
  }
}
