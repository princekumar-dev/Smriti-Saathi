/// Voice Model Registry for True Offline Neural TTS (15 Languages)
/// Maps language and persona to verified Sherpa-ONNX / VITS / MMS models.
library;

import '../../data/app_translations.dart';

enum VoiceTier {
  /// Ready-to-use prebuilt Sherpa bundles (.tar.bz2 containing model.onnx + tokens.txt)
  tierA,

  /// Pre-exported Meta MMS ONNX models from HuggingFace
  tierB,

  /// No public neural bundle; uses calibrated device fallback
  tierC,
}

enum VoiceGender {
  female,
  male,
  neutral,
}

class VoiceModelEntry {
  final String id;
  final String languageId;
  final String languageName;
  final VoiceTier tier;
  final VoiceGender gender;
  final String speakerName;
  final String downloadUrl;
  final String? vocabUrl; // Used for Tier B MMS to generate tokens.txt
  final int sizeBytes;
  final String sizeLabel;
  final bool hasDataDir; // True for Piper/mimic3 voices requiring espeak-ng-data/
  final bool isNeuralAvailable;
  final String archiveFolder; // Name of extracted folder inside the archive

  const VoiceModelEntry({
    required this.id,
    required this.languageId,
    required this.languageName,
    required this.tier,
    required this.gender,
    required this.speakerName,
    required this.downloadUrl,
    this.vocabUrl,
    required this.sizeBytes,
    required this.sizeLabel,
    this.hasDataDir = false,
    this.isNeuralAvailable = true,
    required this.archiveFolder,
  });
}

class VoiceModelRegistry {
  static const String _sherpaBase =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models';

  static const List<VoiceModelEntry> allModels = [
    // ── Tier A: English ──
    VoiceModelEntry(
      id: 'eng_mms',
      languageId: 'en',
      languageName: 'English',
      tier: VoiceTier.tierA,
      gender: VoiceGender.neutral,
      speakerName: 'Natural Voice (MMS)',
      downloadUrl: '$_sherpaBase/vits-mms-eng.tar.bz2',
      sizeBytes: 103 * 1024 * 1024,
      sizeLabel: '~103 MB',
      hasDataDir: false,
      archiveFolder: 'vits-mms-eng',
    ),

    // ── Tier A: Hindi (Dual Recorded Genders) ──
    VoiceModelEntry(
      id: 'hi_IN_priyamvada',
      languageId: 'hi',
      languageName: 'Hindi',
      tier: VoiceTier.tierA,
      gender: VoiceGender.female,
      speakerName: 'Priyamvada (Female)',
      downloadUrl: '$_sherpaBase/vits-piper-hi_IN-priyamvada-medium.tar.bz2',
      sizeBytes: 64 * 1024 * 1024,
      sizeLabel: '~64 MB',
      hasDataDir: true,
      archiveFolder: 'vits-piper-hi_IN-priyamvada-medium',
    ),
    VoiceModelEntry(
      id: 'hi_IN_pratham',
      languageId: 'hi',
      languageName: 'Hindi',
      tier: VoiceTier.tierA,
      gender: VoiceGender.male,
      speakerName: 'Pratham (Male)',
      downloadUrl: '$_sherpaBase/vits-piper-hi_IN-pratham-medium.tar.bz2',
      sizeBytes: 64 * 1024 * 1024,
      sizeLabel: '~64 MB',
      hasDataDir: true,
      archiveFolder: 'vits-piper-hi_IN-pratham-medium',
    ),

    // ── Tier A: Malayalam (Dual Recorded Genders) ──
    VoiceModelEntry(
      id: 'ml_IN_meera',
      languageId: 'ml',
      languageName: 'Malayalam',
      tier: VoiceTier.tierA,
      gender: VoiceGender.female,
      speakerName: 'Meera (Female)',
      downloadUrl: '$_sherpaBase/vits-piper-ml_IN-meera-medium.tar.bz2',
      sizeBytes: 64 * 1024 * 1024,
      sizeLabel: '~64 MB',
      hasDataDir: true,
      archiveFolder: 'vits-piper-ml_IN-meera-medium',
    ),
    VoiceModelEntry(
      id: 'ml_IN_arjun',
      languageId: 'ml',
      languageName: 'Malayalam',
      tier: VoiceTier.tierA,
      gender: VoiceGender.male,
      speakerName: 'Arjun (Male)',
      downloadUrl: '$_sherpaBase/vits-piper-ml_IN-arjun-medium.tar.bz2',
      sizeBytes: 64 * 1024 * 1024,
      sizeLabel: '~64 MB',
      hasDataDir: true,
      archiveFolder: 'vits-piper-ml_IN-arjun-medium',
    ),

    // ── Tier A: Gujarati ──
    VoiceModelEntry(
      id: 'gu_IN_mimic3',
      languageId: 'gu',
      languageName: 'Gujarati',
      tier: VoiceTier.tierA,
      gender: VoiceGender.female,
      speakerName: 'CMU Indic (Natural)',
      downloadUrl: '$_sherpaBase/vits-mimic3-gu_IN-cmu-indic_low.tar.bz2',
      sizeBytes: 76 * 1024 * 1024,
      sizeLabel: '~76 MB',
      hasDataDir: true,
      archiveFolder: 'vits-mimic3-gu_IN-cmu-indic_low',
    ),

    // ── Tier A: Bengali ──
    VoiceModelEntry(
      id: 'bn_coqui',
      languageId: 'bn',
      languageName: 'Bengali',
      tier: VoiceTier.tierA,
      gender: VoiceGender.female,
      speakerName: 'Custom Female (Coqui)',
      downloadUrl: '$_sherpaBase/vits-coqui-bn-custom_female.tar.bz2',
      sizeBytes: 103 * 1024 * 1024,
      sizeLabel: '~103 MB',
      hasDataDir: true,
      archiveFolder: 'vits-coqui-bn-custom_female',
    ),

    // ── Tier A: Nepali ──
    VoiceModelEntry(
      id: 'ne_NP_mimic3',
      languageId: 'ne',
      languageName: 'Nepali',
      tier: VoiceTier.tierA,
      gender: VoiceGender.female,
      speakerName: 'Google Low (mimic3)',
      downloadUrl: '$_sherpaBase/vits-mimic3-ne_NP-ne-google_low.tar.bz2',
      sizeBytes: 76 * 1024 * 1024,
      sizeLabel: '~76 MB',
      hasDataDir: true,
      archiveFolder: 'vits-mimic3-ne_NP-ne-google_low',
    ),

    // ── Tier B: MMS ONNX Models ──
    VoiceModelEntry(
      id: 'tam_mms',
      languageId: 'ta',
      languageName: 'Tamil',
      tier: VoiceTier.tierB,
      gender: VoiceGender.female,
      speakerName: 'Meta MMS Tamil',
      downloadUrl:
          'https://huggingface.co/onnx-community/mms-tts-tam-ONNX/resolve/main/onnx/model.onnx',
      vocabUrl:
          'https://huggingface.co/onnx-community/mms-tts-tam-ONNX/resolve/main/vocab.json',
      sizeBytes: 65 * 1024 * 1024,
      sizeLabel: '~65 MB',
      hasDataDir: false,
      archiveFolder: 'mms-tts-tam-onnx',
    ),
    VoiceModelEntry(
      id: 'tel_mms',
      languageId: 'te',
      languageName: 'Telugu',
      tier: VoiceTier.tierB,
      gender: VoiceGender.female,
      speakerName: 'Meta MMS Telugu',
      downloadUrl:
          'https://huggingface.co/onnx-community/mms-tts-tel-ONNX/resolve/main/onnx/model.onnx',
      vocabUrl:
          'https://huggingface.co/onnx-community/mms-tts-tel-ONNX/resolve/main/vocab.json',
      sizeBytes: 65 * 1024 * 1024,
      sizeLabel: '~65 MB',
      hasDataDir: false,
      archiveFolder: 'mms-tts-tel-onnx',
    ),
    VoiceModelEntry(
      id: 'kan_mms',
      languageId: 'kn',
      languageName: 'Kannada',
      tier: VoiceTier.tierB,
      gender: VoiceGender.female,
      speakerName: 'Meta MMS Kannada',
      downloadUrl:
          'https://huggingface.co/onnx-community/mms-tts-kan-ONNX/resolve/main/onnx/model.onnx',
      vocabUrl:
          'https://huggingface.co/onnx-community/mms-tts-kan-ONNX/resolve/main/vocab.json',
      sizeBytes: 65 * 1024 * 1024,
      sizeLabel: '~65 MB',
      hasDataDir: false,
      archiveFolder: 'mms-tts-kan-onnx',
    ),
    VoiceModelEntry(
      id: 'mar_mms',
      languageId: 'mr',
      languageName: 'Marathi',
      tier: VoiceTier.tierB,
      gender: VoiceGender.female,
      speakerName: 'Meta MMS Marathi',
      downloadUrl:
          'https://huggingface.co/onnx-community/mms-tts-mar-ONNX/resolve/main/onnx/model.onnx',
      vocabUrl:
          'https://huggingface.co/onnx-community/mms-tts-mar-ONNX/resolve/main/vocab.json',
      sizeBytes: 65 * 1024 * 1024,
      sizeLabel: '~65 MB',
      hasDataDir: false,
      archiveFolder: 'mms-tts-mar-onnx',
    ),
    VoiceModelEntry(
      id: 'pan_mms',
      languageId: 'pa',
      languageName: 'Punjabi',
      tier: VoiceTier.tierB,
      gender: VoiceGender.female,
      speakerName: 'Meta MMS Punjabi',
      downloadUrl:
          'https://huggingface.co/onnx-community/mms-tts-pan-ONNX/resolve/main/onnx/model.onnx',
      vocabUrl:
          'https://huggingface.co/onnx-community/mms-tts-pan-ONNX/resolve/main/vocab.json',
      sizeBytes: 65 * 1024 * 1024,
      sizeLabel: '~65 MB',
      hasDataDir: false,
      archiveFolder: 'mms-tts-pan-onnx',
    ),
    VoiceModelEntry(
      id: 'ory_mms',
      languageId: 'or',
      languageName: 'Odia',
      tier: VoiceTier.tierB,
      gender: VoiceGender.female,
      speakerName: 'Meta MMS Odia',
      downloadUrl:
          'https://huggingface.co/onnx-community/mms-tts-ory-ONNX/resolve/main/onnx/model.onnx',
      vocabUrl:
          'https://huggingface.co/onnx-community/mms-tts-ory-ONNX/resolve/main/vocab.json',
      sizeBytes: 65 * 1024 * 1024,
      sizeLabel: '~65 MB',
      hasDataDir: false,
      archiveFolder: 'mms-tts-ory-onnx',
    ),
    VoiceModelEntry(
      id: 'asm_mms',
      languageId: 'as',
      languageName: 'Assamese',
      tier: VoiceTier.tierB,
      gender: VoiceGender.female,
      speakerName: 'Meta MMS Assamese',
      downloadUrl:
          'https://huggingface.co/onnx-community/mms-tts-asm-ONNX/resolve/main/onnx/model.onnx',
      vocabUrl:
          'https://huggingface.co/onnx-community/mms-tts-asm-ONNX/resolve/main/vocab.json',
      sizeBytes: 65 * 1024 * 1024,
      sizeLabel: '~65 MB',
      hasDataDir: false,
      archiveFolder: 'mms-tts-asm-onnx',
    ),

    // ── Tier C: Fallback Only (Manipuri & Mizo) ──
    VoiceModelEntry(
      id: 'mni_fallback',
      languageId: 'mni',
      languageName: 'Manipuri',
      tier: VoiceTier.tierC,
      gender: VoiceGender.neutral,
      speakerName: 'Device Voice (Tuned)',
      downloadUrl: '',
      sizeBytes: 0,
      sizeLabel: 'Device Built-in',
      isNeuralAvailable: false,
      archiveFolder: '',
    ),
    VoiceModelEntry(
      id: 'lus_fallback',
      languageId: 'lus',
      languageName: 'Mizo',
      tier: VoiceTier.tierC,
      gender: VoiceGender.neutral,
      speakerName: 'Device Voice (Tuned)',
      downloadUrl: '',
      sizeBytes: 0,
      sizeLabel: 'Device Built-in',
      isNeuralAvailable: false,
      archiveFolder: '',
    ),
  ];

  /// Find model by language and requested persona/gender.
  ///
  /// Callers pass the language in whatever form they hold it — the app-wide
  /// selection stores the native name (e.g. 'हिन्दी', 'தமிழ்'), while
  /// [VoiceEngine] passes the English name (e.g. 'Hindi'). Normalize any of
  /// those forms (native name, id, English name, or a raw locale/prefix) to the
  /// canonical English language name via [AppTranslations] so the lookup works
  /// regardless of the caller.
  static VoiceModelEntry? getModelFor({
    required String language,
    String persona = 'female',
  }) {
    final raw = language.trim().toLowerCase();
    final info = AppTranslations.getLanguageInfo(language);
    final canonicalName = info.englishName.toLowerCase();
    final localePrefix =
        info.ttsLocale.split(RegExp(r'[-_]')).first.toLowerCase();

    final gender = persona.toLowerCase() == 'male'
        ? VoiceGender.male
        : VoiceGender.female;

    final matching = allModels.where((m) {
      final id = m.languageId.toLowerCase();
      final name = m.languageName.toLowerCase();
      return name == canonicalName ||
          id == localePrefix ||
          id == raw ||
          name == raw;
    }).toList();

    if (matching.isEmpty) return null;

    // Prefer exact gender match
    final exact = matching.firstWhere(
      (m) => m.gender == gender,
      orElse: () => matching.first,
    );
    return exact;
  }

  /// Get model by voice ID
  static VoiceModelEntry? getById(String id) {
    try {
      return allModels.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if neural voice is supported for language
  static bool hasNeuralVoice(String language) {
    final model = getModelFor(language: language);
    return model != null && model.isNeuralAvailable;
  }
}
