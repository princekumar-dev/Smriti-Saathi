import '../data/sample_data.dart';
import 'local_ai_service.dart';
import 'memory_service.dart';

/// Comprehensive AI Conversation & Question-Answering Engine for Smirithi Saathi
class SaathiAiEngine {
  static MemoryItem? _activeRecallMemory;

  static MemoryItem? get activeRecallMemory => _activeRecallMemory;
  static void setActiveRecallMemory(MemoryItem? mem) => _activeRecallMemory = mem;

  /// Generate a contextual, comforting, and direct answer for any user question or command
  static Future<SaathiResponse> generateResponse({
    required String query,
    String userName = '',
    String language = 'English',
  }) async {
    final cleanQuery = query.trim();
    final name = userName.trim().isNotEmpty ? userName.trim() : 'my friend';
    userName = name;
    if (cleanQuery.isEmpty) {
      return SaathiResponse(
        text: "Namaste, $userName... I am listening with love. Please take your time, and tell me whatever is in your heart.",
        topic: 'greeting',
      );
    }

    final lower = cleanQuery.toLowerCase();
    final memService = MemoryService();

    // 0. IF AN ACTIVE MEMORY RECALL QUESTION IS WAITING FOR SENIOR'S ANSWER
    if (_activeRecallMemory != null) {
      final active = _activeRecallMemory!;
      final isCorrect = memService.evaluateAnswer(active, cleanQuery);
      _activeRecallMemory = null; // reset after answer

      if (isCorrect) {
        return SaathiResponse(
          text: "Such a wonderful memory, $userName... That is exactly right: ${active.recallAnswer}. ${active.reminiscenceStory}",
          topic: 'memory_recall_success',
          suggestedAction: 'memories',
        );
      } else {
        return SaathiResponse(
          text: "That was such a sweet try, $userName... For this memory, it was ${active.recallAnswer}. ${active.reminiscenceStory}",
          topic: 'memory_recall_hint',
          suggestedAction: 'memories',
        );
      }
    }

    // 1. TRIGGER MEMORY RECALL QUIZ / RECALL QUESTION
    if (lower.contains('memory question') ||
        lower.contains('test my memory') ||
        lower.contains('ask me a question') ||
        lower.contains('memory quiz') ||
        lower.contains('memory exercise') ||
        lower.contains('quiz')) {
      final recallMem = memService.getRandomRecallMemory();
      if (recallMem != null) {
        _activeRecallMemory = recallMem;
        return SaathiResponse(
          text: "Let's gently reminisce together, $userName... In your memory \"${recallMem.title}\", ${recallMem.recallQuestion}",
          topic: 'memory_quiz',
          suggestedAction: 'memories',
        );
      }
    }

    // 2. TIME / DATE / DAY
    if (lower.contains('time') && (lower.contains('what') || lower.contains('tell') || lower.contains('current') || lower.contains('now'))) {
      final now = DateTime.now();
      final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final minute = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final timeStr = "$hour:$minute $period";
      return SaathiResponse(
        text: "Right now it is $timeStr, $userName... A calm and peaceful time.",
        topic: 'time',
      );
    }

    if (lower.contains('date') || lower.contains('today\'s date') || (lower.contains('what day') || lower.contains('which day'))) {
      final now = DateTime.now();
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      final dayName = weekdays[now.weekday - 1];
      final monthName = months[now.month - 1];
      final dateStr = "$dayName, $monthName ${now.day}, ${now.year}";
      return SaathiResponse(
        text: "Today is $dateStr, $userName. I hope your day is gentle and peaceful.",
        topic: 'date',
      );
    }

    // 3. FULL RAG & TUNED QWEN 2.5 ENGINE INVOCATION
    // Ground family, medicine, safe-zone, memories, and NER conversation in retrieved real facts
    try {
      final aiReply = await LocalAiService.instance.generateReply(
        query: cleanQuery,
        language: language,
        userName: userName,
      );
      if (aiReply.trim().isNotEmpty) {
        String? action;
        String topic = 'ai_conversation';
        if (lower.contains('medicine') || lower.contains('pill') || lower.contains('dose') || lower.contains('routine') || lower.contains('schedule')) {
          action = 'routine';
          topic = 'routine';
        } else if (lower.contains('family') || lower.contains('daughter') || lower.contains('son') || lower.contains('call') || lower.contains('who is') || lower.contains('who are')) {
          action = 'family';
          topic = 'family';
        } else if (lower.contains('memory') || lower.contains('photo') || lower.contains('trip') || lower.contains('story') || lower.contains('remember')) {
          action = 'memories';
          topic = 'memory';
        } else if (lower.contains('song') || lower.contains('music') || lower.contains('game') || lower.contains('activity')) {
          action = 'activities';
          topic = 'activities';
        }
        return SaathiResponse(
          text: aiReply,
          topic: topic,
          suggestedAction: action,
        );
      }
    } catch (_) {}

    // 4. GREETINGS & WELL-BEING (OFFLINE HEURISTIC FALLBACK)
    if (lower.startsWith('hi') ||
        lower.startsWith('hello') ||
        lower.startsWith('namaste') ||
        lower.startsWith('vanakkam') ||
        lower.startsWith('good morning') ||
        lower.startsWith('good afternoon') ||
        lower.startsWith('good evening')) {
      final hour = DateTime.now().hour;
      String greeting = 'Namaste';
      if (hour < 12) {
        greeting = 'Good morning';
      } else if (hour < 17) {
        greeting = 'Good afternoon';
      } else {
        greeting = 'Good evening';
      }
      return SaathiResponse(
        text: "$greeting, $userName... It is so lovely to be with you. How are you feeling right now? Take your time, I am listening.",
        topic: 'greeting',
      );
    }

    if (lower.contains('how are you') || lower.contains('who are you') || lower.contains('what is your name')) {
      if (lower.contains('who are you') || lower.contains('your name')) {
        return SaathiResponse(
          text: "I am Saathi, your caring companion and friend, $userName. I am always right here by your side to listen, share memories, and keep you company.",
          topic: 'identity',
        );
      }
      return SaathiResponse(
        text: "I am feeling so peaceful being here with you, $userName... Thank you for asking. How has your day been feeling?",
        topic: 'smalltalk',
      );
    }

    // 4. EMOTIONAL & HEALTH EXPRESSIONS
    if (lower.contains('happy') || lower.contains('feeling good') || lower.contains('great') || lower.contains('peaceful') || lower.contains('wonderful')) {
      return SaathiResponse(
        text: "Hearing that brings such warmth to my heart, $userName... A peaceful mind and cheerful heart are the greatest blessings.",
        topic: 'health',
      );
    }

    if (lower.contains('tired') || lower.contains('sleepy') || lower.contains('exhausted') || lower.contains('rest')) {
      return SaathiResponse(
        text: "Please rest comfortably, $userName... Sit back gently, take a sip of warm water, and close your eyes. I am right here keeping you company.",
        topic: 'health',
      );
    }

    if (lower.contains('headache') || lower.contains('pain') || lower.contains('dizzy') || lower.contains('not feeling well') || lower.contains('sick') || lower.contains('hurt') || lower.contains('fever')) {
      return SaathiResponse(
        text: "I am so sorry you are uncomfortable, $userName... Please sit back, take a slow, gentle breath. I will make a note for your caregiver, and please drink a warm sip of water.",
        topic: 'health_alert',
      );
    }

    if (lower.contains('lonely') || lower.contains('sad') || lower.contains('bored') || lower.contains('alone')) {
      return SaathiResponse(
        text: "You are never alone, $userName... I am right here beside you. You are loved, and you are safe. Would you like to hear an old story, listen to soft music, or just sit quietly together?",
        topic: 'comfort',
        suggestedAction: 'memories',
      );
    }

    // 5. MEDICINE & ROUTINE / SCHEDULE
    if (lower.contains('medicine') || lower.contains('tablet') || lower.contains('pill') || lower.contains('dose')) {
      if (lower.contains('did i') || lower.contains('have i') || lower.contains('take')) {
        return SaathiResponse(
          text: "Your morning routine includes your blood pressure and wellbeing vitamins. If you haven't taken them after breakfast yet, please take them with a warm glass of water.",
          topic: 'routine',
          suggestedAction: 'routine',
        );
      }
      return SaathiResponse(
        text: "Your medication schedule is tracked in your Daily Routine. You have a morning reminder at 9:00 AM and an evening reminder at 7:30 PM.",
        topic: 'routine',
        suggestedAction: 'routine',
      );
    }

    if (lower.contains('schedule') || lower.contains('routine') || (lower.contains('today') && (lower.contains('plan') || lower.contains('what do i have') || lower.contains('remind')))) {
      final rems = SampleData.reminders;
      if (rems.isEmpty) {
        return const SaathiResponse(
          text: "You have no upcoming reminders scheduled right now. Everything is calm and peaceful. Would you like to listen to music or look at photos?",
          topic: 'routine',
          suggestedAction: 'routine',
        );
      }
      final titles = rems.map((r) => "${r['time']}: ${r['title']}").join(", ");
      return SaathiResponse(
        text: "Here is your routine for today: $titles. You are on track!",
        topic: 'routine',
        suggestedAction: 'routine',
      );
    }

    // 6. FAMILY & PERSONS (TAGGED BY CARETAKER)
    if (lower.contains('family') || lower.contains('daughter') || lower.contains('son') || lower.contains('granddaughter') || lower.contains('children') || lower.contains('loved ones')) {
      return const SaathiResponse(
        text: "Your family and caregivers care deeply about you. You can open your Family Circle anytime to see your loved ones or give them a call with one tap.",
        topic: 'family',
        suggestedAction: 'family',
      );
    }

    // 7. STORIES & MEMORIES (CURATED BY CARETAKER)
    if (lower.contains('story') || lower.contains('tales') || lower.contains('katha')) {
      return SaathiResponse(
        text: "Once upon a time in a quiet southern town, early mornings began with the sweet sound of temple bells and the aroma of freshly roasted filter coffee. Neighbors would gather in the courtyard under the shaded mango tree to share smiles and stories. Life was simple, peaceful, and warm.",
        topic: 'story',
      );
    }

    if (lower.contains('house') || lower.contains('old home') || lower.contains('childhood') || lower.contains('pongal') || lower.contains('temple') || lower.contains('memory') || lower.contains('memories') || lower.contains('photo') || lower.contains('photos') || lower.contains('video')) {
      if (lower.contains('pongal')) {
        return SaathiResponse(
          text: "Pongal has always been a special festival in your family! Everyone gathered in the courtyard as the fresh sweet pot boiled over with cheers of 'Pongalo Pongal', with Meena, Arun, and Lakshmi sharing sugarcane and laughter.",
          topic: 'memory',
          suggestedAction: 'memories',
        );
      }
      if (lower.contains('house') || lower.contains('old home')) {
        return SaathiResponse(
          text: "The old ancestral home had tall wooden pillars, a sunny open central courtyard, and red oxide floors that stayed cool even in the peak of summer. So many beautiful memories were born there.",
          topic: 'memory',
          suggestedAction: 'memories',
        );
      }
      return SaathiResponse(
        text: "Your memory album has photos and stories of family festivals, graduation days, and trips added by your caretaker. Would you like to view them now or try a memory question?",
        topic: 'memory',
        suggestedAction: 'memories',
      );
    }

    // 8. MUSIC & SONGS & ACTIVITIES
    if (lower.contains('song') || lower.contains('music') || lower.contains('bhajan') || lower.contains('sing') || lower.contains('carnatic') || lower.contains('devotional')) {
      return SaathiResponse(
        text: "Listening to calming melodies brings peace to the soul. I recommend a soothing morning Raga like Kalyani or a gentle MS Subbulakshmi bhajan. Shall we open the Activities player?",
        topic: 'music',
        suggestedAction: 'activities',
      );
    }

    if (lower.contains('joke') || lower.contains('laugh') || lower.contains('funny')) {
      return SaathiResponse(
        text: "Here is a lighthearted joke for you: Why do birds fly south for winter? Because walking would take much too long! I hope that brought a little smile to your face.",
        topic: 'joke',
      );
    }

    if (lower.contains('game') || lower.contains('puzzle') || lower.contains('quiz') || lower.contains('activity')) {
      return SaathiResponse(
        text: "We have fun memory match activities, story-telling, and gentle brain exercises ready for you in the Activities section. Let's exercise our minds together!",
        topic: 'activities',
        suggestedAction: 'activities',
      );
    }

    // 9. GENERAL KNOWLEDGE & ASSISTANCE
    if (lower.contains('coffee') || lower.contains('tea')) {
      return SaathiResponse(
        text: "Authentic South Indian filter coffee is brewed with freshly roasted chicory blend decoction, mixed with hot frothed whole milk and a touch of jaggery or sugar, poured high between two dabarahs!",
        topic: 'knowledge',
      );
    }

    if (lower.contains('weather')) {
      return SaathiResponse(
        text: "The weather today is pleasant with a gentle calm breeze. It's a wonderful day to sit by the window or balcony and enjoy the fresh air.",
        topic: 'weather',
      );
    }

    if (lower.contains('capital of india')) {
      return SaathiResponse(
        text: "The capital of India is New Delhi.",
        topic: 'knowledge',
      );
    }

    if (lower.contains('why is the sky blue')) {
      return SaathiResponse(
        text: "The sky looks blue because sunlight reaches Earth's atmosphere and is scattered in all directions by gases and particles in the air. Blue light travels in smaller, shorter waves, so it scatters more than other colors!",
        topic: 'knowledge',
      );
    }

    if (lower.contains('how to stay healthy') || lower.contains('health tips')) {
      return SaathiResponse(
        text: "Simple daily secrets for good health: drink plenty of warm water, take a gentle 15-minute walk, enjoy balanced home-cooked meals, and keep your heart happy with family conversations!",
        topic: 'health',
      );
    }

    if (lower.contains('help') || lower.contains('what can you do')) {
      return SaathiResponse(
        text: "I can help you with anything: tell you today's schedule, recall family members, tell soothing stories, share daily health reminders, ask memory quiz questions, or simply chat like a loyal companion.",
        topic: 'help',
      );
    }

    // 10. LOCAL AI COMPANION (QWEN 2.5 / MULTILINGUAL ADAPTIVE ENGINE)
    try {
      final aiReply = await LocalAiService.instance.generateReply(
        query: cleanQuery,
        language: language,
        userName: userName,
      );
      if (aiReply.isNotEmpty) {
        return SaathiResponse(
          text: aiReply,
          topic: 'ai_conversation',
        );
      }
    } catch (_) {
      // Fallback to offline rule-based conversational answer
    }

    final directAnswer = _generateConversationalAnswer(cleanQuery, userName);
    return SaathiResponse(
      text: directAnswer,
      topic: 'general',
    );
  }

  static String _generateConversationalAnswer(String query, String userName) {
    final lower = query.toLowerCase();
    if (query.endsWith('?') ||
        lower.startsWith('what') ||
        lower.startsWith('why') ||
        lower.startsWith('where') ||
        lower.startsWith('how') ||
        lower.startsWith('when') ||
        lower.startsWith('who') ||
        lower.startsWith('can you') ||
        lower.startsWith('could you') ||
        lower.startsWith('tell me')) {
      return "That is such a thoughtful question, $userName... I am listening and reflecting with you. While I keep learning every day, please know I am always right by your side. We can also check with your family or caregiver whenever you need special assistance.";
    }

    return "I hear you, $userName... Thank you for sharing your thoughts with me. It brings me such comfort to sit and talk with you. Please take your time, and tell me whatever is in your heart.";
  }
}

class SaathiResponse {
  final String text;
  final String topic;
  final String? suggestedAction;

  const SaathiResponse({
    required this.text,
    required this.topic,
    this.suggestedAction,
  });
}
