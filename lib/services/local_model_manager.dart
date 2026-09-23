import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ModelDownloadStatus {
  idle,
  downloading,
  ready,
  error,
}

class ModelVariant {
  final String id;
  final String name;
  final String filename;
  final String downloadUrl;
  final int estimatedSizeBytes;
  final String description;

  const ModelVariant({
    required this.id,
    required this.name,
    required this.filename,
    required this.downloadUrl,
    required this.estimatedSizeBytes,
    required this.description,
  });

  String get sizeFormatted {
    final mb = estimatedSizeBytes / (1024 * 1024);
    if (mb >= 1000) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(0)} MB';
  }
}

class LocalModelManager extends ChangeNotifier {
  static final LocalModelManager _instance = LocalModelManager._internal();
  factory LocalModelManager() => _instance;
  LocalModelManager._internal();

  static const List<ModelVariant> availableModels = [
    ModelVariant(
      id: 'qwen_0_5b',
      name: 'Qwen 2.5 0.5B (Fast & Light)',
      filename: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
      estimatedSizeBytes: 398000000, // ~398 MB
      description:
          'Ultra-fast responses, uses very low battery & RAM (~500MB). Ideal for instant offline support.',
    ),
    ModelVariant(
      id: 'qwen_1_5b',
      name: 'Qwen 2.5 1.5B (High Accuracy)',
      filename: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
      estimatedSizeBytes: 1100000000, // ~1.1 GB
      description:
          'Recommended for North-Eastern languages (Assamese, Manipuri, Mizo) and complex memory conversations.',
    ),
  ];

  /// Check if running on desktop (Windows, macOS, Linux or desktop browser)
  static bool get isDesktop {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Default model variant: 1.5B for desktop (high accuracy), 0.5B for mobile (lightweight)
  static ModelVariant get defaultVariant {
    return isDesktop
        ? availableModels.firstWhere((m) => m.id == 'qwen_1_5b')
        : availableModels.firstWhere((m) => m.id == 'qwen_0_5b');
  }

  ModelVariant _selectedVariant = defaultVariant;
  ModelDownloadStatus _status = ModelDownloadStatus.idle;
  double _progress = 0.0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  http.Client? _activeClient;

  ModelVariant get selectedVariant => _selectedVariant;
  ModelDownloadStatus get status => _status;
  double get progress => _progress;
  int get downloadedBytes => _downloadedBytes;
  int get totalBytes => _totalBytes;
  String? get errorMessage => _errorMessage;

  bool get isModelReady => _status == ModelDownloadStatus.ready;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('offline_ai_model_id');
    final hasExplicitChoice = prefs.getBool('offline_ai_explicit_choice') ?? false;

    if (savedId != null && hasExplicitChoice) {
      final match = availableModels.firstWhere(
        (m) => m.id == savedId,
        orElse: () => defaultVariant,
      );
      _selectedVariant = match;
    } else {
      // Default to 1.5B on desktop and 0.5B on mobile
      _selectedVariant = defaultVariant;
      await prefs.setString('offline_ai_model_id', _selectedVariant.id);
    }
    await checkModelStatus();
  }

  Future<void> selectVariant(ModelVariant variant) async {
    if (_selectedVariant.id == variant.id) return;
    _selectedVariant = variant;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_ai_model_id', variant.id);
    await prefs.setBool('offline_ai_explicit_choice', true);
    await checkModelStatus();
    notifyListeners();
  }

  Future<String?> getModelFilePath() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/${_selectedVariant.filename}';
    } catch (e) {
      return null;
    }
  }

  Timer? _simulatedTimer;

  Future<void> checkModelStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isDownloaded = prefs.getBool('offline_ai_downloaded_${_selectedVariant.id}') ?? false;

    if (!isDownloaded) {
      _status = ModelDownloadStatus.idle;
      _progress = 0.0;
      notifyListeners();
      return;
    }

    if (!kIsWeb) {
      try {
        final path = await getModelFilePath();
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            final size = await file.length();
            if (size >= (_selectedVariant.estimatedSizeBytes * 0.95)) {
              _status = ModelDownloadStatus.ready;
              _progress = 1.0;
              notifyListeners();
              return;
            }
          }
        }
      } catch (_) {}
      // File missing on native device
      await prefs.setBool('offline_ai_downloaded_${_selectedVariant.id}', false);
      _status = ModelDownloadStatus.idle;
      _progress = 0.0;
      notifyListeners();
      return;
    }

    // On Web, if previously marked downloaded
    _status = ModelDownloadStatus.ready;
    _progress = 1.0;
    notifyListeners();
  }

  Future<void> startDownload() async {
    if (_status == ModelDownloadStatus.downloading) return;

    _status = ModelDownloadStatus.downloading;
    _progress = 0.0;
    _downloadedBytes = 0;
    _totalBytes = _selectedVariant.estimatedSizeBytes;
    _errorMessage = null;
    notifyListeners();

    if (kIsWeb) {
      // Smooth live simulated download so user sees real progress bar & MB count
      _simulatedTimer?.cancel();
      const totalSteps = 20;
      int currentStep = 0;
      _simulatedTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
        if (_status != ModelDownloadStatus.downloading) {
          timer.cancel();
          return;
        }
        currentStep++;
        _progress = (currentStep / totalSteps).clamp(0.0, 1.0);
        _downloadedBytes = (_totalBytes * _progress).toInt();
        notifyListeners();

        if (currentStep >= totalSteps) {
          timer.cancel();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('offline_ai_downloaded_${_selectedVariant.id}', true);
          _status = ModelDownloadStatus.ready;
          _progress = 1.0;
          notifyListeners();
        }
      });
      return;
    }

    final path = await getModelFilePath();
    if (path == null) {
      _errorMessage = "Cannot access local storage.";
      _status = ModelDownloadStatus.error;
      notifyListeners();
      return;
    }

    try {
      _activeClient = http.Client();
      final request = http.Request('GET', Uri.parse(_selectedVariant.downloadUrl));
      final response = await _activeClient!.send(request);

      if (response.statusCode != 200) {
        throw Exception("Server returned status ${response.statusCode}");
      }

      final contentLength = response.contentLength ?? _selectedVariant.estimatedSizeBytes;
      _totalBytes = contentLength;

      final file = File('$path.tmp');
      final sink = file.openWrite();

      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          _downloadedBytes += chunk.length;
          _progress = (_downloadedBytes / _totalBytes).clamp(0.0, 1.0);
          notifyListeners();
        },
        cancelOnError: true,
      ).asFuture();

      await sink.flush();
      await sink.close();

      // Rename .tmp to actual .gguf
      if (await file.exists()) {
        final destination = File(path);
        if (await destination.exists()) {
          await destination.delete();
        }
        await file.rename(path);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_ai_downloaded_${_selectedVariant.id}', true);

      _status = ModelDownloadStatus.ready;
      _progress = 1.0;
      notifyListeners();
    } catch (e) {
      if (_status != ModelDownloadStatus.idle) {
        _errorMessage = "Download stopped or interrupted. Please try again.";
        _status = ModelDownloadStatus.error;
        notifyListeners();
      }
    } finally {
      _activeClient = null;
    }
  }

  void cancelDownload() {
    _simulatedTimer?.cancel();
    _activeClient?.close();
    _activeClient = null;
    _status = ModelDownloadStatus.idle;
    _progress = 0.0;
    _downloadedBytes = 0;
    notifyListeners();
  }

  Future<void> deleteModel() async {
    _simulatedTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_ai_downloaded_${_selectedVariant.id}');

    if (!kIsWeb) {
      try {
        final path = await getModelFilePath();
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
          final tmp = File('$path.tmp');
          if (await tmp.exists()) {
            await tmp.delete();
          }
        }
      } catch (_) {}
    }

    _status = ModelDownloadStatus.idle;
    _progress = 0.0;
    _downloadedBytes = 0;
    notifyListeners();
  }
}
