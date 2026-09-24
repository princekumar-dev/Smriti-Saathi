import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/app_translations.dart';
import 'ai/ai_model_provider.dart';
import 'rag_service.dart';

class LocalAiService {
  static final LocalAiService _instance = LocalAiService._internal();
  factory LocalAiService() => _instance;
  LocalAiService._internal();

  static LocalAiService get instance => _instance;

  /// Ordered chain of pluggable model providers (§22). Online server model is
  /// tried first, then on-device; if neither answers we fall back to the
  /// multilingual heuristic. Later, a real on-device runtime only has to make
  /// [OfflineAIProvider.complete] return text — nothing else changes.
  final List<AIModelProvider> _providers = [
    OnlineAIProvider(),
    OfflineAIProvider(),
  ];

  /// Build a compassionate ChatML prompt optimized for Qwen 2.5
  String buildChatMLPrompt({
    required String query,
    required String language,
    String userName = '',
    String ragContext = '',
  }) {
    if (ragContext.isNotEmpty) {
      return RagService.instance.buildRagPrompt(
        query: query,
        ragContext: ragContext,
        language: language,
        userName: userName,
      );
    }

    final senior = userName.trim().isNotEmpty ? userName.trim() : 'my dear friend';
    final langInfo = AppTranslations.getLanguageInfo(language);
    final langName = langInfo.englishName;

    return '''<|im_start|>system
You are Smriti Saathi, a gentle, compassionate, and reassuring companion for $senior, an elder who may experience moments of memory loss.
Current spoken language: $langName (${langInfo.nativeName}).
Guidelines:
- Reply directly in $langName using warm, respectful words.
- Keep your answers short (1 to 2 calm sentences), easy to understand and listen to.
- Never show medical panic, frustration, or complex tech jargon.
- Offer peace, reassurance, and emotional comfort.
<|im_end|>
<|im_start|>user
$query
<|im_end|>
<|im_start|>assistant
''';
  }

  /// Generate an AI response through the provider chain, falling back to the
  /// offline multilingual heuristic when no model answers.
  Future<String> generateReply({
    required String query,
    required String language,
    String userName = '',
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return '';

    // RAG: Retrieve personalized memories, routines, patient facts + graph.
    String ragContext = '';
    try {
      ragContext = await RagService.instance.retrieveContext(
        query: cleanQuery,
        language: language,
      );
    } catch (_) {}

    final prompt = buildChatMLPrompt(
      query: cleanQuery,
      language: language,
      userName: userName,
      ragContext: ragContext,
    );
    final req = AiRequest(
      query: cleanQuery,
      language: language,
      userName: userName,
      ragContext: ragContext,
      prompt: prompt,
    );

    // Try each pluggable provider in order; first non-empty reply wins.
    for (final provider in _providers) {
      try {
        if (!await provider.isAvailable()) continue;
        final reply = await provider.complete(req);
        if (reply != null && reply.isNotEmpty) return reply;
      } catch (e) {
        debugPrint('[LocalAiService] provider ${provider.id} failed: $e');
      }
    }

    // Compassionate offline conversational fallback (zero network required).
    return _generateOfflineFallback(
      query: cleanQuery,
      language: language,
      userName: userName,
      ragContext: ragContext,
    );
  }

  /// Smart multilingual offline fallback engine covering North-Eastern and Indic languages
  String _generateOfflineFallback({
    required String query,
    required String language,
    String userName = '',
    String ragContext = '',
  }) {
    final senior = userName.trim().isNotEmpty ? userName.trim() : 'my friend';
    final lower = query.toLowerCase();
    final langInfo = AppTranslations.getLanguageInfo(language);
    final lang = langInfo.englishName.toLowerCase();

    // RAG fallback grounding: if question is about medication, family, safe zone or memory
    if (ragContext.isNotEmpty) {
      if (lower.contains('where am i') || lower.contains('where is my house') || lower.contains('home') || lower.contains('lost')) {
        return "You are resting safely in your peaceful home, $senior... Your loved ones and I are right here watching over you.";
      }
      if (lower.contains('medicine') || lower.contains('pill') || lower.contains('dose') || lower.contains('tablet') || lower.contains('routine')) {
        return "Based on your schedule, $senior: $ragContext";
      }
      if (lower.contains('family') || lower.contains('daughter') || lower.contains('son') || lower.contains('who')) {
        return "Here is your family information, $senior: $ragContext";
      }
      if (lower.contains('remember') || lower.contains('memory') || lower.contains('photo') || lower.contains('trip')) {
        return "Here is your cherished memory, $senior: $ragContext";
      }
    }

    // 0. Math and arithmetic calculation (e.g. 12 * 12, 15 + 25)
    final mathReg = RegExp(r'(\d+(?:\.\d+)?)\s*([\+\-\*\/xX×÷])\s*(\d+(?:\.\d+)?)');
    final mathMatch = mathReg.firstMatch(query);
    if (mathMatch != null) {
      final a = double.tryParse(mathMatch.group(1) ?? '') ?? 0;
      final op = mathMatch.group(2) ?? '';
      final b = double.tryParse(mathMatch.group(3) ?? '') ?? 0;
      double? resVal;
      String opSymbol = '×';
      if (op == '+') { resVal = a + b; opSymbol = '+'; }
      else if (op == '-') { resVal = a - b; opSymbol = '−'; }
      else if (op == '*' || op.toLowerCase() == 'x' || op == '×') { resVal = a * b; opSymbol = '×'; }
      else if (op == '/' || op == '÷') { if (b != 0) resVal = a / b; opSymbol = '÷'; }

      if (resVal != null) {
        final formattedResult = resVal % 1 == 0 ? resVal.toInt().toString() : resVal.toStringAsFixed(2);
        final formattedA = a % 1 == 0 ? a.toInt().toString() : a.toString();
        final formattedB = b % 1 == 0 ? b.toInt().toString() : b.toString();
        if (lang.contains('tamil')) {
          return "$formattedA $opSymbol $formattedB என்பது $formattedResult, $senior... உங்கள் நினைவாற்றல் மிகவும் கூர்மையாக உள்ளது!";
        } else if (lang.contains('hindi')) {
          return "$formattedA $opSymbol $formattedB का उत्तर $formattedResult है, $senior... आपका मन बहुत तेज है!";
        } else if (lang.contains('assamese')) {
          return "$formattedA $opSymbol $formattedB হ'ল $formattedResult, $senior... আপোনাৰ বুদ্ধি অতি তীক্ষ্ণ!";
        } else if (lang.contains('manipuri')) {
          return "$formattedA $opSymbol $formattedB দি $formattedResult নি, $senior। নহাক্না য়াম্না ফনা খংই!";
        } else if (lang.contains('mizo')) {
          return "$formattedA $opSymbol $formattedB chu $formattedResult a ni, $senior... I rilru a fing hle mai!";
        } else if (lang.contains('nepali')) {
          return "$formattedA $opSymbol $formattedB को उत्तर $formattedResult हो, $senior... हजुरको दिमाग धेरै तेज छ!";
        } else if (lang.contains('telugu')) {
          return "$formattedA $opSymbol $formattedB అంటే $formattedResult, $senior... మీ జ్ఞాపకశక్తి చాలా బాగుంది!";
        } else {
          return "$formattedA $opSymbol $formattedB is $formattedResult, $senior... Your mind is so sharp and active!";
        }
      }
    }

    // North-Eastern: Assamese (অসমীয়া)
    if (lang.contains('assamese')) {
      if (lower.contains('where') || lower.contains('home') || lower.contains('ঘৰ') || lower.contains('ক’ত')) {
        return "আপুনি নিজৰ মৰমৰ ঘৰতেই সুৰক্ষিতভাৱে বিশ্ৰাম কৰি আছে, $senior... চিন্তা নকৰিব, মই আৰু আপোনাৰ পৰিয়াল আপোনাৰ ওচৰতেই আছোঁ।";
      }
      if (lower.contains('worried') || lower.contains('scared') || lower.contains('fear') || lower.contains('ভয়')) {
        return "চিন্তা নকৰিব, $senior... মই আপোনাৰ ওচৰতে আছোঁ। আপুনি সম্পূৰ্ণ সুৰক্ষিত।";
      }
      return "নমস্কাৰ, $senior। মই আপোনাৰ কথাবোৰ শুনিলোঁ। মই সদায়েই আপোনাৰ লগত আছোঁ।";
    }

    // North-Eastern: Manipuri (মৈতৈলোন্ / Meiteilon)
    if (lang.contains('manipuri')) {
      if (lower.contains('where') || lower.contains('home') || lower.contains('য়ুম')) {
        return "নহাক্কী ইমুংদা নহাক শান্ত ওইনা লৈরি, $senior... অকিবা লৈগনবা, ঐ নহাক্কী নক্ননা লৈরি।";
      }
      if (lower.contains('worried') || lower.contains('scared') || lower.contains('fear')) {
        return "অকিবা লৈগনবা, $senior... ঐ নহাক্কী নক্ননা লৈরি। নহাক শান্ত ওইনা লৈয়ু।";
      }
      return "খুরুমজরি, $senior। ঐ নহাক্কী স্মৃতী সাথীনি। ঐ নহাক্কী পাউ শুনবা য়াই।";
    }

    // North-Eastern: Mizo
    if (lang.contains('mizo')) {
      if (lower.contains('where') || lower.contains('home') || lower.contains('in')) {
        return "I in lumah him takin i awm e, $senior... Hlau suh aw, i chhungte leh keimah i kiangah kan awm reng e.";
      }
      if (lower.contains('worried') || lower.contains('scared') || lower.contains('fear')) {
        return "Hlau suh aw, $senior... I kiangah ka awm reng e. I him a nia.";
      }
      return "Chibai, $senior. I țawngkam hi ka hria e, i kiangah ka awm tlat.";
    }

    // North-Eastern / Himalayan: Nepali (नेपाली)
    if (lang.contains('nepali')) {
      if (lower.contains('where') || lower.contains('home') || lower.contains('घर') || lower.contains('कहाँ')) {
        return "हजुर आफ्नै घरमा सुरक्षित र आरामसँग हुनुहुन्छ, $senior... चिन्ता नलिनुहोस्, हामी हजुरकै साथमा छौं।";
      }
      if (lower.contains('worried') || lower.contains('scared') || lower.contains('fear') || lower.contains('डर')) {
        return "चिन्ता नलिनुहोस्, $senior... म तपाईंकै साथमा छु। तपाईं सुरक्षित हुनुहुन्छ।";
      }
      return "नमस्ते, $senior। म तपाईंको कुरा सुन्दैछु, हजुरलाई सहयोग गर्न पाउँदा खुसी लाग्यो।";
    }

    // North-Eastern: Manipuri / Meitei
    if (lang.contains('manipuri') || lang.contains('meitei')) {
      return "খুরুমজরি, $senior... ঐহাক নখোইগা লোয়ননা লৈরি, নখোইগী ৱারী পাউ শুনবা য়াই।";
    }

    // North-Eastern: Mizo
    if (lang.contains('mizo')) {
      if (lower.contains('worried') || lower.contains('scared') || lower.contains('fear')) {
        return "Hlau suh aw, $senior... I kiangah ka awm reng e. I him a nia.";
      }
      return "Chibai, $senior. I țawngkam hi ka hria e, i kiangah ka awm tlat.";
    }

    // North-Eastern / Himalayan: Nepali
    if (lang.contains('nepali')) {
      if (lower.contains('worried') || lower.contains('scared') || lower.contains('fear')) {
        return "चिन्ता नलिनुहोस्, $senior... म तपाईंकै साथमा छु। तपाईं सुरक्षित हुनुहुन्छ।";
      }
      return "नमस्ते, $senior। म तपाईंको कुरा सुन्दैछु, हजुरलाई सहयोग गर्न पाउँदा खुसी लाग्यो।";
    }

    // Tamil
    if (lang.contains('tamil')) {
      if (lower.contains('worried') || lower.contains('scared') || lower.contains('fear') || lower.contains('பயம்')) {
        return "பயப்படாதீர்கள், $senior... நான் உங்கள் அருகிலேயே இருக்கிறேன். நீங்கள் முற்றிலும் பாதுகாப்பாக இருக்கிறீர்கள்.";
      }
      return "வணக்கம், $senior... நீங்கள் கூறியதைக் கேட்டேன். நான் எப்போதும் உங்களுடன் இருப்பேன்.";
    }

    // Telugu
    if (lang.contains('telugu')) {
      if (lower.contains('worried') || lower.contains('scared') || lower.contains('fear')) {
        return "భయపడవద్దు, $senior... నేను మీతోనే ఉన్నాను. మీరు సురక్షితంగా ఉన్నారు.";
      }
      return "నమస్కారం, $senior... మీ మాటలు నేను వింటున్నాను. నేను ఎల్లప్పుడూ మీ తోడుగా ఉంటాను.";
    }

    // Kannada
    if (lang.contains('kannada')) {
      return "ನಮಸ್ಕಾರ, $senior... ನಾನು ನಿಮ್ಮ ಮಾತುಗಳನ್ನು ಪ್ರೀತಿಯಿಂದ ಕೇಳುತ್ತಿದ್ದೇನೆ. ನಾನು ನಿಮ್ಮ ಜೊತೆಗಿದ್ದೇನೆ.";
    }

    // Malayalam
    if (lang.contains('malayalam')) {
      return "നമസ്കാരം, $senior... പേടിക്കേണ്ടതില്ല, ഞാൻ എപ്പോഴും നിങ്ങളുടെ കൂടെയുണ്ട്.";
    }

    // Hindi
    if (lang.contains('hindi')) {
      if (lower.contains('worried') || lower.contains('scared') || lower.contains('डर') || lower.contains('चिंता')) {
        return "घबराइए मत, $senior... मैं आपके बिल्कुल पास हूँ। आप पूरी तरह सुरक्षित हैं।";
      }
      return "नमस्ते, $senior... मैंने आपकी बात सुनी। मैं हर समय आपके साथ हूँ, आप निश्चिंत रहें।";
    }

    // Default English
    if (lower.contains('worried') || lower.contains('scared') || lower.contains('fear') || lower.contains('alone')) {
      return "Please don't worry, $senior... Take a gentle breath. I am right here with you, and you are safe.";
    }
    if (lower.contains('how are you') || lower.contains('who are you')) {
      return "I am Smriti Saathi, your companion, $senior. Being here by your side brings me great peace.";
    }
    return "I hear you with all my heart, $senior... I am always right here beside you.";
  }
}
