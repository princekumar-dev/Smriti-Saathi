import 'package:flutter_test/flutter_test.dart';
import 'package:smirithi_saathi/services/voice_engine.dart';

void main() {
  group('VoiceEngine Text Sanitization Tests', () {
    test('strips markdown asterisks, ticks, and formatting', () {
      const raw = 'Hello **Amma**! Remember this *special* day: `family memory`!';
      final clean = VoiceEngine.cleanTextForSpeech(raw);
      expect(clean, 'Hello Amma! Remember this special day: family memory!');
    });

    test('strips emojis cleanly without leaving residue', () {
      const raw = 'Namaste Amma! 🌅 Look at this memory: Wedding Day 💍 at 8:00 AM... 🌸 Cherish it! 👵';
      final clean = VoiceEngine.cleanTextForSpeech(raw);
      expect(clean.contains('🌅'), isFalse);
      expect(clean.contains('💍'), isFalse);
      expect(clean.contains('🌸'), isFalse);
      expect(clean.contains('👵'), isFalse);
      expect(clean, contains('8 AM'));
    });

    test('cleans times cleanly for natural speech', () {
      const raw = 'It is 8:00 AM right now. Later at 2:30 PM we will have tea.';
      final clean = VoiceEngine.cleanTextForSpeech(raw);
      expect(clean, 'It is 8 AM right now. Later at 2 30 PM we will have tea.');
    });

    test('replaces Dr. with Doctor and cleans symbols', () {
      const raw = 'Please visit Dr. Sharma & take medicine / water.';
      final clean = VoiceEngine.cleanTextForSpeech(raw);
      expect(clean, contains('Doctor Sharma'));
      expect(clean, contains(' and '));
      expect(clean, contains(' or '));
    });
  });

  group('VoiceEngine Soothing Humanization Tests', () {
    test('softens abrupt exclamation points into calm periods to avoid robotic pitch spikes', () {
      const raw = 'Namaste Amma! How wonderful!';
      final soothing = VoiceEngine.humanizeForSoothingSpeech(raw);
      expect(soothing.contains('!'), isFalse);
      expect(soothing, contains('.'));
    });

    test('adds gentle breath pauses after greetings and affectionate vocatives', () {
      const raw = 'Namaste, Amma, I am right here with you.';
      final soothing = VoiceEngine.humanizeForSoothingSpeech(raw);
      expect(soothing, contains('Namaste... '));
      expect(soothing, contains('Amma... '));
    });

    test('adds unhurried pauses to reassuring conversational phrases', () {
      const raw = 'Take your time. I hear you and I am right here.';
      final soothing = VoiceEngine.humanizeForSoothingSpeech(raw);
      expect(soothing, contains('Take your time...'));
      expect(soothing, contains('I hear you...'));
      expect(soothing, contains('I am right here...'));
    });

    test('handles regional vocatives and greetings with soothing pauses', () {
      const hindi = 'नमस्ते, माँ, चिंता मत कीजिए।';
      final hindiSoothing = VoiceEngine.humanizeForSoothingSpeech(hindi);
      expect(hindiSoothing, contains('नमस्ते...'));

      const bengali = 'নমস্কার, মা, কেমন আছেন?';
      final bengaliSoothing = VoiceEngine.humanizeForSoothingSpeech(bengali);
      expect(bengaliSoothing, contains('নমস্কার...'));
      expect(bengaliSoothing, contains('মা...'));
    });

    test('combines clean sanitization with soothing inflection without emoji artifacts', () {
      const complex = '🌸 Hello, Amma! **Look** at this photo! 😊 Take your time...';
      final soothing = VoiceEngine.humanizeForSoothingSpeech(complex);
      expect(soothing.contains('🌸'), isFalse);
      expect(soothing.contains('😊'), isFalse);
      expect(soothing.contains('*'), isFalse);
      expect(soothing.contains('!'), isFalse);
      expect(soothing, contains('Hello... Amma...'));
      expect(soothing, contains('Take your time...'));
    });
  });

  group('VoiceEngine Indic Romanization & Phonetic Fallback Tests', () {
    test('transliterates known regional greetings to smooth phonetic English', () {
      expect(
        VoiceEngine.romanizeIndicScript('नमस्ते और स्वागत है'),
        'Namaste aur swaagat hai',
      );
      expect(
        VoiceEngine.romanizeIndicScript('নমস্কাৰ আৰু স্বাগতম'),
        'Nomoskar aaru swaagotom',
      );
      expect(
        VoiceEngine.romanizeIndicScript('নমস্কার ও স্বাগতম'),
        'Nomoshkar o swaagotom',
      );
      expect(
        VoiceEngine.romanizeIndicScript('খুরুমজরি অমসুং তরাম্না ওকচরি'),
        'Khurumjari amsung taramna okchari',
      );
      expect(
        VoiceEngine.romanizeIndicScript('नमस्ते र स्वागत छ'),
        'Namaste ra swaagat chha',
      );
    });

    test('dynamically transliterates unknown Indic sentences to speakable Latin phonemes', () {
      const hindiText = 'स्मृति साथी';
      final romanized = VoiceEngine.romanizeIndicScript(hindiText);
      expect(romanized, isNotEmpty);
      expect(RegExp(r'[\u0900-\u097F]').hasMatch(romanized), isFalse);

      const bengaliText = 'শান্তি ও আনন্দ';
      final bengaliRomanized = VoiceEngine.romanizeIndicScript(bengaliText);
      expect(bengaliRomanized, isNotEmpty);
      expect(RegExp(r'[\u0980-\u09FF]').hasMatch(bengaliRomanized), isFalse);
    });
  });
}
