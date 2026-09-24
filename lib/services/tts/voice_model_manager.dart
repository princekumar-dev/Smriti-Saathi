import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'voice_model_registry.dart';

enum VoiceModelState {
  notDownloaded,
  downloading,
  ready,
  failed,
}

class VoiceModelManager extends ChangeNotifier {
  static final VoiceModelManager _instance = VoiceModelManager._internal();
  factory VoiceModelManager() => _instance;
  VoiceModelManager._internal() {
    _initStorage();
  }

  final Map<String, VoiceModelState> _states = {};
  final Map<String, double> _progress = {};
  final Map<String, String> _errors = {};
  Directory? _baseDir;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  VoiceModelState getState(String voiceId) =>
      _states[voiceId] ?? VoiceModelState.notDownloaded;

  double getProgress(String voiceId) => _progress[voiceId] ?? 0.0;

  String? getError(String voiceId) => _errors[voiceId];

  bool isReady(String voiceId) => getState(voiceId) == VoiceModelState.ready;

  Future<void> _initStorage() async {
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      final appSupport = await getApplicationSupportDirectory();
      _baseDir = Directory('${appSupport.path}/tts_models');
      if (!await _baseDir!.exists()) {
        await _baseDir!.create(recursive: true);
      }

      // Check existing downloaded models
      for (final model in VoiceModelRegistry.allModels) {
        if (!model.isNeuralAvailable) continue;
        if (await _verifyModelFiles(model)) {
          _states[model.id] = VoiceModelState.ready;
        } else {
          _states[model.id] = VoiceModelState.notDownloaded;
        }
      }
    } catch (e) {
      debugPrint('[VoiceModelManager] Init storage error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Get local directory where this voice model is stored
  Future<Directory?> getModelDirectory(VoiceModelEntry entry) async {
    if (kIsWeb) return null;
    if (_baseDir == null) await _initStorage();
    if (_baseDir == null) return null;
    return Directory('${_baseDir!.path}/${entry.id}');
  }

  /// Verify that model.onnx and tokens.txt exist and are valid
  Future<bool> _verifyModelFiles(VoiceModelEntry entry) async {
    if (kIsWeb) return false;
    final dir = await getModelDirectory(entry);
    if (dir == null || !await dir.exists()) return false;

    final modelFile = File('${dir.path}/model.onnx');
    final tokensFile = File('${dir.path}/tokens.txt');

    if (!await modelFile.exists() || !await tokensFile.exists()) {
      return false;
    }

    final modelSize = await modelFile.length();
    final tokensSize = await tokensFile.length();
    return modelSize > 1000000 && tokensSize > 10;
  }

  /// Download and extract voice model on demand
  Future<bool> downloadModel(
    VoiceModelEntry entry, {
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) return false;
    if (!entry.isNeuralAvailable) return false;

    if (getState(entry.id) == VoiceModelState.ready) {
      return true;
    }
    if (getState(entry.id) == VoiceModelState.downloading) {
      return false;
    }

    _states[entry.id] = VoiceModelState.downloading;
    _progress[entry.id] = 0.0;
    _errors.remove(entry.id);
    notifyListeners();

    try {
      final targetDir = await getModelDirectory(entry);
      if (targetDir == null) throw Exception('Storage unavailable');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      if (entry.tier == VoiceTier.tierA) {
        // Download .tar.bz2 archive
        await _downloadAndExtractTarBz2(entry, targetDir, onProgress);
      } else if (entry.tier == VoiceTier.tierB) {
        // Download ONNX model directly + convert vocab.json to tokens.txt
        await _downloadTierBModel(entry, targetDir, onProgress);
      }

      // Normalize file names so the loader always finds model.onnx / tokens.txt
      await _normalizeModelFiles(targetDir);

      // Final integrity verification
      final isSuccess = await _verifyModelFiles(entry);
      if (isSuccess) {
        _states[entry.id] = VoiceModelState.ready;
        _progress[entry.id] = 1.0;
        notifyListeners();
        return true;
      } else {
        throw Exception('Downloaded files failed integrity check');
      }
    } catch (e) {
      debugPrint('[VoiceModelManager] Download error for ${entry.id}: $e');
      _states[entry.id] = VoiceModelState.failed;
      _errors[entry.id] = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sherpa-ONNX bundles don't all name their weights `model.onnx` — Piper and
  /// mimic3 archives ship `<voice>.onnx`, and tokens can arrive as `tokens.txt`
  /// nested one level down. The loader ([NeuralTtsService]) and [_verifyModelFiles]
  /// both expect a flat `model.onnx` + `tokens.txt`, so reconcile the layout here.
  Future<void> _normalizeModelFiles(Directory targetDir) async {
    if (kIsWeb) return;
    try {
      final modelFile = File('${targetDir.path}/model.onnx');
      final tokensFile = File('${targetDir.path}/tokens.txt');

      // Scan the extracted tree once for stray onnx / tokens files.
      final entities = await targetDir.list(recursive: true).toList();

      if (!await modelFile.exists()) {
        File? candidate;
        for (final e in entities) {
          if (e is File && e.path.toLowerCase().endsWith('.onnx')) {
            // Prefer the largest .onnx (the actual acoustic model).
            if (candidate == null ||
                await e.length() > await candidate.length()) {
              candidate = e;
            }
          }
        }
        if (candidate != null) {
          await candidate.copy(modelFile.path);
        }
      }

      if (!await tokensFile.exists()) {
        for (final e in entities) {
          if (e is File &&
              e.path.replaceAll('\\', '/').toLowerCase().endsWith('tokens.txt')) {
            await e.copy(tokensFile.path);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('[VoiceModelManager] normalize error: $e');
    }
  }

  Future<void> _downloadAndExtractTarBz2(
    VoiceModelEntry entry,
    Directory targetDir,
    void Function(double progress)? onProgress,
  ) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(entry.downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode} from server');
      }

      final contentLength = response.contentLength ?? entry.sizeBytes;
      final bytes = <int>[];
      int received = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          final p = (received / contentLength).clamp(0.0, 0.9);
          _progress[entry.id] = p;
          onProgress?.call(p);
          notifyListeners();
        }
      }

      // Extraction phase (represented as 0.9 to 1.0)
      _progress[entry.id] = 0.92;
      notifyListeners();

      // Decompress bzip2 in memory
      final decompressed = BZip2Decoder().decodeBytes(bytes);
      final archive = TarDecoder().decodeBytes(decompressed);

      for (final file in archive) {
        final filename = file.name;
        // Strip out enclosing directory name if present
        var relativePath = filename;
        if (entry.archiveFolder.isNotEmpty &&
            relativePath.startsWith('${entry.archiveFolder}/')) {
          relativePath =
              relativePath.substring(entry.archiveFolder.length + 1);
        }

        if (relativePath.isEmpty) continue;
        final outPath = '${targetDir.path}/$relativePath';

        if (file.isFile) {
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(outPath).create(recursive: true);
        }
      }
    } finally {
      client.close();
    }
  }

  Future<void> _downloadTierBModel(
    VoiceModelEntry entry,
    Directory targetDir,
    void Function(double progress)? onProgress,
  ) async {
    final client = http.Client();
    try {
      // 1. Download model.onnx
      final request = http.Request('GET', Uri.parse(entry.downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode} downloading ONNX model');
      }

      final contentLength = response.contentLength ?? entry.sizeBytes;
      final modelFile = File('${targetDir.path}/model.onnx');
      final sink = modelFile.openWrite();
      int received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          final p = (received / contentLength).clamp(0.0, 0.9);
          _progress[entry.id] = p;
          onProgress?.call(p);
          notifyListeners();
        }
      }
      await sink.flush();
      await sink.close();

      // 2. Download vocab.json and convert to tokens.txt
      if (entry.vocabUrl != null && entry.vocabUrl!.isNotEmpty) {
        final vocabResp = await client.get(Uri.parse(entry.vocabUrl!));
        if (vocabResp.statusCode == 200) {
          final vocabMap = jsonDecode(vocabResp.body) as Map<String, dynamic>;
          final tokensBuffer = StringBuffer();
          vocabMap.forEach((token, id) {
            tokensBuffer.writeln('$token $id');
          });
          final tokensFile = File('${targetDir.path}/tokens.txt');
          await tokensFile.writeAsString(tokensBuffer.toString());
        } else {
          throw Exception('Failed to download vocab: ${vocabResp.statusCode}');
        }
      }
    } finally {
      client.close();
    }
  }

  /// Remove downloaded voice model to free device storage
  Future<void> deleteModel(VoiceModelEntry entry) async {
    if (kIsWeb) return;
    try {
      final dir = await getModelDirectory(entry);
      if (dir != null && await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _states[entry.id] = VoiceModelState.notDownloaded;
      _progress.remove(entry.id);
      _errors.remove(entry.id);
      notifyListeners();
    } catch (e) {
      debugPrint('[VoiceModelManager] Error deleting ${entry.id}: $e');
    }
  }
}
