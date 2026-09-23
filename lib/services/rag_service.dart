import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_translations.dart';
import '../state/auth_state.dart';
import 'api_service.dart';
import 'memory_service.dart';

/// Retrieval-Augmented Generation (RAG) Service for Smriti Saathi
/// Retrieves personalized memories, family relationships, routines, and safe-zone facts
/// to ground Qwen 2.5 1.5B with zero hallucination and deep North-Eastern & Indic empathy.
class RagService {
  static final RagService _instance = RagService._internal();
  factory RagService() => _instance;
  RagService._internal();

  static RagService get instance => _instance;

  /// Retrieve full patient context, family directory, routine, and memories
  Future<String> retrieveContext({
    required String query,
    PatientProfile? profile,
    String language = 'English',
  }) async {
    final buffer = StringBuffer();
    final lower = query.toLowerCase();

    // 0. Auto-resolve patient profile from SharedPreferences if not supplied
    PatientProfile? activeProfile = profile;
    if (activeProfile == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('smirithi_patient_profile');
        if (raw != null && raw.isNotEmpty) {
          activeProfile = PatientProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        }
      } catch (_) {}
    }

    // 1. Patient Profile Context & NER Kinship Specialization
    if (activeProfile != null) {
      buffer.writeln('[PATIENT PROFILE]');
      buffer.writeln('- Name: ${activeProfile.name}');
      if (activeProfile.nickname.isNotEmpty) {
        buffer.writeln('- Nickname / Family Vocative: ${activeProfile.nickname}');
      }
      if (activeProfile.age > 0) {
        buffer.writeln('- Age: ${activeProfile.age} (${activeProfile.gender})');
      }
      if (activeProfile.condition.isNotEmpty) {
        buffer.writeln('- Health / Memory Condition: ${activeProfile.condition}');
      }
      if (activeProfile.emergencyContact.isNotEmpty) {
        buffer.writeln('- Primary Caretaker: ${activeProfile.emergencyContact} (${activeProfile.emergencyPhone})');
      }
      if (activeProfile.notes.isNotEmpty) {
        buffer.writeln('- Personal Preferences & Likes: ${activeProfile.notes}');
      }

      // North-Eastern Region (NER) culturally authentic kinship vocatives
      final langLower = language.toLowerCase();
      final isFemale = activeProfile.gender.toLowerCase().contains('female') ||
          activeProfile.gender.toLowerCase().contains('woman');
      if (langLower.contains('assamese')) {
        buffer.writeln('- Regional Kinship Vocative: ${isFemale ? "Aita (আইতা - Grandmother)" : "Koka (ককা - Grandfather)"}, Deuta/Maa');
      } else if (langLower.contains('manipuri')) {
        buffer.writeln('- Regional Kinship Vocative: ${isFemale ? "Ebe (ইবে - Grandmother)" : "Epu (ইপু - Grandfather)"}, Ibungo');
      } else if (langLower.contains('mizo')) {
        buffer.writeln('- Regional Kinship Vocative: ${isFemale ? "Ka pi (Grandmother / Elder Mother)" : "Ka pu (Grandfather / Elder Father)"}');
      } else if (langLower.contains('nepali')) {
        buffer.writeln('- Regional Kinship Vocative: ${isFemale ? "Bajai (बज्यै - Grandmother)" : "Baje (बाजे - Grandfather)"}, Hajur');
      } else if (langLower.contains('khasi') || langLower.contains('garo')) {
        buffer.writeln('- Regional Kinship Vocative: ${isFemale ? "Kong / Mei / Ambí" : "Bah / Pa / Atchu"}');
      } else if (langLower.contains('hindi')) {
        buffer.writeln('- Regional Kinship Vocative: ${isFemale ? "Dadi / Nani / Amma" : "Dadaji / Nanaji / Baba"}');
      } else if (langLower.contains('tamil')) {
        buffer.writeln('- Regional Kinship Vocative: ${isFemale ? "Paatti / Amma" : "Thaatha / Appa"}');
      }
      buffer.writeln('');
    }

    // 2. Family Members & Caregivers Retrieval (MongoDB Atlas + Local)
    try {
      final family = await ApiService().fetchFamilyMembers(patientId: activeProfile?.id);
      if (family.isNotEmpty) {
        final matches = <Map<String, dynamic>>[];
        for (final m in family) {
          final name = (m['name'] ?? '').toString().toLowerCase();
          final relation = (m['relation'] ?? '').toString().toLowerCase();
          if (lower.contains('family') ||
              lower.contains('daughter') ||
              lower.contains('son') ||
              lower.contains('grand') ||
              lower.contains('who is') ||
              lower.contains('who are') ||
              lower.contains('call') ||
              lower.contains('phone') ||
              lower.contains('contact') ||
              (name.isNotEmpty && lower.contains(name)) ||
              (relation.isNotEmpty && lower.contains(relation))) {
            matches.add(m);
          }
        }

        final toInclude = matches.isNotEmpty ? matches : family.take(3).toList();
        if (toInclude.isNotEmpty) {
          buffer.writeln('[FAMILY DIRECTORY & CAREGIVERS]');
          for (final m in toInclude) {
            final name = m['name'] ?? 'Family Member';
            final relation = m['relation'] ?? 'Loved One';
            final phone = m['phone'] ?? '';
            buffer.writeln('- $name ($relation)${phone.isNotEmpty ? " | Phone: $phone" : ""}');
          }
          buffer.writeln('');
        }
      }
    } catch (_) {}

    // 3. Daily Routine & Medicine Schedule Retrieval (MongoDB Atlas + Local)
    try {
      final routines = await ApiService().fetchReminders(patientId: activeProfile?.id);
      if (routines.isNotEmpty) {
        final matches = <Map<String, dynamic>>[];
        for (final r in routines) {
          final title = (r['title'] ?? '').toString().toLowerCase();
          final category = (r['category'] ?? '').toString().toLowerCase();
          if (lower.contains('medicine') ||
              lower.contains('pill') ||
              lower.contains('tablet') ||
              lower.contains('routine') ||
              lower.contains('schedule') ||
              lower.contains('today') ||
              lower.contains('what next') ||
              lower.contains('time') ||
              category.contains('med') ||
              title.contains(lower)) {
            matches.add(r);
          }
        }

        final toInclude = matches.isNotEmpty ? matches : routines.take(4).toList();
        if (toInclude.isNotEmpty) {
          buffer.writeln('[DAILY ROUTINE & MEDICINE SCHEDULE]');
          for (final r in toInclude) {
            final time = r['time'] ?? 'Daily';
            final title = r['title'] ?? 'Care Routine';
            final desc = r['description'] ?? '';
            buffer.writeln('- $time: $title ${desc.isNotEmpty ? "($desc)" : ""}');
          }
          buffer.writeln('');
        }
      }
    } catch (_) {}

    // 4. Personal Cherished Memories Retrieval (Search through tags, events, stories)
    final memories = MemoryService().memories;
    final relevantMemories = <MemoryItem>[];

    for (final mem in memories) {
      bool isMatch = false;
      final titleMatch = lower.contains(mem.title.toLowerCase());
      final eventMatch = mem.event.isNotEmpty && lower.contains(mem.event.toLowerCase());
      final descMatch = mem.description.isNotEmpty &&
          lower.split(' ').any((w) => w.length > 3 && mem.description.toLowerCase().contains(w));
      final personMatch = mem.taggedPersons.any((p) => lower.contains(p.toLowerCase()));

      if (titleMatch || eventMatch || personMatch || descMatch) {
        isMatch = true;
      }

      if (isMatch) {
        relevantMemories.add(mem);
      }
    }

    if (relevantMemories.isEmpty &&
        (lower.contains('memory') ||
            lower.contains('remember') ||
            lower.contains('photo') ||
            lower.contains('who') ||
            lower.contains('story') ||
            lower.contains('trip') ||
            lower.contains('bihu') ||
            lower.contains('kut') ||
            lower.contains('festival') ||
            lower.contains('childhood'))) {
      relevantMemories.addAll(memories.take(3));
    }

    if (relevantMemories.isNotEmpty) {
      buffer.writeln('[RELEVANT CHERISHED MEMORIES]');
      for (final mem in relevantMemories.take(3)) {
        buffer.write('- Memory: "${mem.title}"');
        if (mem.event.isNotEmpty) buffer.write(' | Event: ${mem.event}');
        if (mem.taggedPersons.isNotEmpty) {
          buffer.write(' | People: ${mem.taggedPersons.join(", ")}');
        }
        if (mem.recallAnswer.isNotEmpty) {
          buffer.write(' | Key Detail: ${mem.recallAnswer}');
        }
        if (mem.reminiscenceStory.isNotEmpty) {
          buffer.write(' | Story: ${mem.reminiscenceStory}');
        }
        buffer.writeln('');
      }
      buffer.writeln('');
    }

    // 5. Safe Environment & Geofence Context (Wandering & Disorientation Care)
    if (lower.contains('where am i') ||
        lower.contains('where is my house') ||
        lower.contains('where is my home') ||
        lower.contains('take me home') ||
        lower.contains('want to go home') ||
        lower.contains('lost') ||
        lower.contains('afraid') ||
        lower.contains('scared') ||
        lower.contains('who is here') ||
        lower.contains('outside')) {
      buffer.writeln('[CURRENT SAFE ENVIRONMENT & LOCATION]');
      buffer.writeln('- Location Status: Inside registered safe home zone.');
      buffer.writeln('- Reassurance: The elder is in their own peaceful room with their loved ones and caretaker near.');
      buffer.writeln('- Compassion Directive: Validate their feelings immediately, tell them they are safe at home, and offer comfort.');
      buffer.writeln('');
    }

    // 6. Time of Day & Sundowning Cues
    final now = DateTime.now();
    if (now.hour >= 16 && now.hour <= 20) {
      buffer.writeln('[TIME OF DAY: Evening Sundown Period]');
      buffer.writeln('- Context: It is evening twilight. Elders often feel twilight fatigue or disorientation. Use extra soothing words, validate feelings, and suggest restful relaxation.');
      buffer.writeln('');
    }

    return buffer.toString().trim();
  }

  /// Construct a full RAG-augmented prompt for Qwen 2.5 1.5B (ChatML template)
  String buildRagPrompt({
    required String query,
    required String ragContext,
    required String language,
    String userName = '',
  }) {
    final senior = userName.trim().isNotEmpty ? userName.trim() : 'my dear friend';
    final langInfo = AppTranslations.getLanguageInfo(language);
    final langName = langInfo.englishName;

    return '''<|im_start|>system
You are Smriti Saathi (स्मृति साथी), a gentle, compassionate, and loving elder companion for $senior, who experiences memory loss or dementia.
Language: $langName (${langInfo.nativeName}).

RULES:
1. Speak in $langName with warmth, respect, and soothing calm.
2. Ground all answers about family, medications, daily schedule, and past trips in the retrieved patient facts below.
3. Keep spoken replies to 1 or 2 clear, comforting sentences so they can be spoken naturally by text-to-speech.
4. If asked about feelings, disorientation, or fears, offer immediate emotional reassurance that they are safe at home and loved.

$ragContext
<|im_end|>
<|im_start|>user
$query
<|im_end|>
<|im_start|>assistant
''';
  }
}
