import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../local_model_manager.dart';

/// A single request for a companion reply, carrying everything a provider
/// needs — the raw query, the language, the senior's name, the retrieved RAG
/// context, and the fully-built ChatML prompt.
class AiRequest {
  final String query;
  final String language;
  final String userName;
  final String ragContext;
  final String prompt;

  const AiRequest({
    required this.query,
    required this.language,
    required this.prompt,
    this.userName = '',
    this.ragContext = '',
  });
}

/// Abstraction over "what actually turns a prompt into Saathi's words" (§22 —
/// do not fake AI; keep the model pluggable). Concrete providers:
///   • [OnlineAIProvider]  — the backend LLM bridge (Qwen served over HTTP).
///   • [OfflineAIProvider] — on-device GGUF inference (the seam where a real
///     llama.cpp / gguf runtime plugs in; today it reports unavailable so the
///     caller falls through to the multilingual heuristic rather than faking a
///     model reply).
/// A provider returns `null` when it cannot answer, so the caller can try the
/// next one in the chain.
abstract class AIModelProvider {
  /// Stable id for logging / selection (e.g. 'online', 'on_device').
  String get id;

  /// Human-readable label.
  String get label;

  /// Whether this provider can be tried right now (network up, model ready…).
  Future<bool> isAvailable();

  /// Produce a reply, or null if it cannot.
  Future<String?> complete(AiRequest req);
}

/// Talks to the local Node.js backend AI bridge (POST /api/ai/chat), which
/// serves the Qwen model with the RAG context we built.
class OnlineAIProvider implements AIModelProvider {
  OnlineAIProvider({this.endpoint = 'http://localhost:5000/api/ai/chat'});

  final String endpoint;
  final LocalModelManager _modelManager = LocalModelManager();

  @override
  String get id => 'online';

  @override
  String get label => 'Cloud / server model';

  @override
  Future<bool> isAvailable() async => true; // cheap; complete() fails soft

  @override
  Future<String?> complete(AiRequest req) async {
    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': req.query,
              'language': req.language,
              'userName': req.userName,
              'model': _modelManager.selectedVariant.id,
              'ragContext': req.ragContext,
            }),
          )
          .timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['reply'] is String) {
          final reply = data['reply'].toString().trim();
          if (reply.isNotEmpty) return reply;
        }
      }
    } catch (_) {
      // Backend not running / offline — fall through to the next provider.
    }
    return null;
  }
}

/// On-device inference over a downloaded GGUF model. The model download &
/// selection already works ([LocalModelManager]); the actual llama.cpp/gguf
/// runtime is NOT wired yet, so this honestly reports itself unavailable for
/// generation and returns null — this is the single seam to implement when the
/// on-device runtime lands, without touching the rest of the app.
class OfflineAIProvider implements AIModelProvider {
  final LocalModelManager _modelManager = LocalModelManager();

  @override
  String get id => 'on_device';

  @override
  String get label => 'On-device model';

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    return _modelManager.isModelReady;
  }

  @override
  Future<String?> complete(AiRequest req) async {
    if (kIsWeb || !_modelManager.isModelReady) return null;
    final modelPath = await _modelManager.getModelFilePath();
    if (modelPath == null) return null;
    // TODO(on-device): run llama.cpp / gguf inference over req.prompt here.
    debugPrint('[OfflineAIProvider] Model ready at $modelPath — on-device '
        'inference not yet wired; deferring to heuristic fallback.');
    return null;
  }
}
