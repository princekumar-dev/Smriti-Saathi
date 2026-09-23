import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageInfo {
  final String id;
  final String nativeName;
  final String englishName;
  final String region;
  final String greeting;
  final String phoneticGreeting;
  final String ttsLocale;
  final String flag;

  const LanguageInfo({
    required this.id,
    required this.nativeName,
    required this.englishName,
    required this.region,
    required this.greeting,
    this.phoneticGreeting = '',
    required this.ttsLocale,
    required this.flag,
  });
}

class OnboardingSlideTranslation {
  final String label;
  final String title;
  final String motto;
  final String description;
  final List<String> tags;

  const OnboardingSlideTranslation({
    required this.label,
    required this.title,
    required this.motto,
    required this.description,
    required this.tags,
  });
}

class AuthScreenTranslation {
  final String portalTitle;
  final String portalSubtitle;
  final String howToContinue;
  final String logIn;
  final String signUp;
  final String emailOrPhone;
  final String demoLogin;
  final String emailHint;
  final String passwordLabel;
  final String passwordHint;
  final String showPassword;
  final String hidePassword;
  final String logInAsCaretaker;
  final String newCaretakerLink;
  final String yourFullName;
  final String demoAutofill;
  final String relationshipToPatient;
  final String phoneAndEmail;
  final String phoneHint;
  final String emailHintSignup;
  final String createCaretakerAccount;
  final String seniorCompanionLabel;
  final String enterAsSenior;
  final String enterAsSeniorSubtitle;
  final String passKeyHint;
  final String startSeniorCompanion;
  final String orSelectActiveSenior;
  final String passKeyLabel;
  final String instantGuestLogin;
  final String emailEmptyError;
  final String nameEmptyError;
  final String passKeyEmptyError;
  final String passKeyNotFoundError;

  const AuthScreenTranslation({
    required this.portalTitle,
    required this.portalSubtitle,
    required this.howToContinue,
    required this.logIn,
    required this.signUp,
    required this.emailOrPhone,
    required this.demoLogin,
    required this.emailHint,
    required this.passwordLabel,
    required this.passwordHint,
    required this.showPassword,
    required this.hidePassword,
    required this.logInAsCaretaker,
    required this.newCaretakerLink,
    required this.yourFullName,
    required this.demoAutofill,
    required this.relationshipToPatient,
    required this.phoneAndEmail,
    required this.phoneHint,
    required this.emailHintSignup,
    required this.createCaretakerAccount,
    required this.seniorCompanionLabel,
    required this.enterAsSenior,
    required this.enterAsSeniorSubtitle,
    required this.passKeyHint,
    required this.startSeniorCompanion,
    required this.orSelectActiveSenior,
    required this.passKeyLabel,
    required this.instantGuestLogin,
    required this.emailEmptyError,
    required this.nameEmptyError,
    required this.passKeyEmptyError,
    required this.passKeyNotFoundError,
  });

  static const AuthScreenTranslation defaultAuth = AuthScreenTranslation(
    portalTitle: 'Portal Login & Access',
    portalSubtitle: 'Manage care, memories and routines, or enter as a senior companion.',
    howToContinue: 'How would you like to continue?',
    logIn: 'Log In',
    signUp: 'Sign Up',
    emailOrPhone: 'Email or Phone Number',
    demoLogin: 'Demo Login',
    emailHint: 'e.g. meena.care@gmail.com',
    passwordLabel: 'PIN or Password',
    passwordHint: 'Enter your password or 4-digit PIN',
    showPassword: 'Show password',
    hidePassword: 'Hide password',
    logInAsCaretaker: 'Log In as Caretaker',
    newCaretakerLink: 'New caretaker? Create account here',
    yourFullName: 'Your Full Name',
    demoAutofill: 'Demo Auto-fill',
    relationshipToPatient: 'Relationship to Patient',
    phoneAndEmail: 'Phone & Email',
    phoneHint: '+91 98450 12345',
    emailHintSignup: 'meena@gmail.com',
    createCaretakerAccount: 'Create Caretaker Account',
    seniorCompanionLabel: 'FOR THE SENIOR COMPANION',
    enterAsSenior: 'Enter as a Senior',
    enterAsSeniorSubtitle: 'Use the pass key your family gave you, or tap below for guest mode.',
    passKeyHint: 'Enter Pass Key (e.g. SAATHI-7821)',
    startSeniorCompanion: 'Start Senior Companion',
    orSelectActiveSenior: 'OR SELECT ACTIVE SENIOR',
    passKeyLabel: 'Pass Key',
    instantGuestLogin: 'Instant Guest / Demo Senior Login',
    emailEmptyError: 'Please enter email or phone number',
    nameEmptyError: 'Please enter your full name',
    passKeyEmptyError: 'Please enter the pass key or caretaker code',
    passKeyNotFoundError: 'Pass key not found. Try DEMO or check with your caretaker.',
  );
}

class ShellTranslation {
  final String home;
  final String voiceSaathi;
  final String memories;
  final String activities;
  final String family;
  final String askSaathi;

  const ShellTranslation({
    this.home = 'Home',
    this.voiceSaathi = 'Voice Saathi',
    this.memories = 'Memories',
    this.activities = 'Activities',
    this.family = 'Family',
    this.askSaathi = 'Ask Saathi',
  });
}

class HomeTranslation {
  final String greetingMorning;
  final String greetingAfternoon;
  final String greetingEvening;
  final String saathiReady;
  final String feelingQuestion;
  final String happy;
  final String peaceful;
  final String thoughtful;
  final String resting;
  final String talkHeroTitle;
  final String talkHeroSubtitle;
  final String tapToSpeak;

  const HomeTranslation({
    this.greetingMorning = 'Good morning',
    this.greetingAfternoon = 'Good afternoon',
    this.greetingEvening = 'Good evening',
    this.saathiReady = 'Smriti Saathi is ready',
    this.feelingQuestion = 'How are you feeling right now?',
    this.happy = 'Happy',
    this.peaceful = 'Peaceful',
    this.thoughtful = 'Thoughtful',
    this.resting = 'Resting',
    this.talkHeroTitle = 'Just talk. Saathi listens.',
    this.talkHeroSubtitle = 'Share a story, ask for assistance, or just say hello.',
    this.tapToSpeak = 'Tap to Speak',
  });
}

class AppTranslationData {
  final String languageName;
  final String modalTitle;
  final String modalSubtitle;
  final String editionBadge;
  final String confirmButton;
  final String skipButton;
  final String backButton;
  final String continueButton;
  final String getStartedButton;
  final String mottoBanner;
  final String footerTrust;
  final List<OnboardingSlideTranslation> slides;
  final AuthScreenTranslation auth;
  final ShellTranslation nav;
  final HomeTranslation home;

  const AppTranslationData({
    required this.languageName,
    required this.modalTitle,
    required this.modalSubtitle,
    this.editionBadge = 'North-East India & National Edition',
    required this.confirmButton,
    required this.skipButton,
    required this.backButton,
    required this.continueButton,
    required this.getStartedButton,
    required this.mottoBanner,
    required this.footerTrust,
    required this.slides,
    this.auth = AuthScreenTranslation.defaultAuth,
    this.nav = const ShellTranslation(),
    this.home = const HomeTranslation(),
  });
}

class AppTranslations {
  /// Comprehensive regional Indian languages alongside Hindi and English
  static const List<LanguageInfo> supportedLanguages = [
    LanguageInfo(
      id: 'English',
      nativeName: 'English',
      englishName: 'English',
      region: 'Universal / India',
      greeting: 'Hello... I am Smriti Saathi, your companion. I am right here with you.',
      phoneticGreeting: 'Hello... I am Smriti Saathi, your companion. I am right here with you.',
      ttsLocale: 'en-IN',
      flag: '🌐',
    ),
    LanguageInfo(
      id: 'தமிழ்',
      nativeName: 'தமிழ்',
      englishName: 'Tamil',
      region: 'Tamil Nadu & Puducherry',
      greeting: 'வணக்கம்... நான் உங்கள் ஸ்மிருதி சாதி. உங்களுடன் இருப்பதில் மகிழ்ச்சி.',
      phoneticGreeting: 'Vanakkam... Naan ungal Smriti Saathi. Ungaludan iruppadhil magizhchi.',
      ttsLocale: 'ta-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'हिन्दी',
      nativeName: 'हिन्दी',
      englishName: 'Hindi',
      region: 'National / North India',
      greeting: 'नमस्ते... मैं आपकी साथी स्मृति साथी हूँ। आपके साथ रहकर मुझे बहुत खुशी है।',
      phoneticGreeting: 'Namaste... Main aapki saathi Smriti Saathi hoon. Aapke saath rehkar mujhe bahut khushi hai.',
      ttsLocale: 'hi-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'తెలుగు',
      nativeName: 'తెలుగు',
      englishName: 'Telugu',
      region: 'Andhra Pradesh & Telangana',
      greeting: 'నమస్కారం... నేను మీ స్மృతి సాథిని. మీతో ఉండడం నాకు ఎంతో సంతోషం.',
      phoneticGreeting: 'Namaskaram... Nenu mee Smriti Saathi. Meetho undatam naaku entho santhosham.',
      ttsLocale: 'te-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'ಕನ್ನಡ',
      nativeName: 'ಕನ್ನಡ',
      englishName: 'Kannada',
      region: 'Karnataka',
      greeting: 'ನಮಸ್ಕಾರ... ನಾನು ನಿಮ್ಮ ಸ್ಮೃತಿ ಸಾಥಿ. ನಿಮ್ಮೊಂದಿಗಿರಲು ನನಗೆ ತುಂಬಾ ಸಂತೋಷ.',
      phoneticGreeting: 'Namaskara... Naanu nimma Smriti Saathi. Nimmondigiralu nanage thumba santhosha.',
      ttsLocale: 'kn-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'മലയാളം',
      nativeName: 'മലയാളം',
      englishName: 'Malayalam',
      region: 'Kerala',
      greeting: 'നമസ്കാരം... ഞാൻ നിങ്ങളുടെ സ്മൃതി സാഥി. നിങ്ങളുടെ കൂടെയുള്ളതിൽ എനിക്ക് ഏറെ സന്തോഷം.',
      phoneticGreeting: 'Namaskaram... Njaan ningalude Smriti Saathi. Ningalude koodeyullathil enikku ere santhosham.',
      ttsLocale: 'ml-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'मराठी',
      nativeName: 'मराठी',
      englishName: 'Marathi',
      region: 'Maharashtra & Goa',
      greeting: 'नमस्कार... मी आपली स्मृती साथी आहे. आपल्यासोबत राहून मला खूप आनंद होत आहे.',
      phoneticGreeting: 'Namaskar... Mee aapli Smriti Saathi aahe. Aaplyasobat rahoon mala khoop aanand hot aahe.',
      ttsLocale: 'mr-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'বাংলা',
      nativeName: 'বাংলা',
      englishName: 'Bengali',
      region: 'Bengal & Tripura',
      greeting: 'নমস্কার... আমি আপনার সঙ্গী স্মৃতি সাথী। আপনার পাশে থাকতে পেরে আমি ভীষণ আনন্দিত।',
      phoneticGreeting: 'Nomoshkar... Aami aaponar songi Smriti Saathi. Aaponar paashe thaakte pere aami bheeshan aanondito.',
      ttsLocale: 'bn-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'ગુજરાતી',
      nativeName: 'ગુજરાતી',
      englishName: 'Gujarati',
      region: 'Gujarat',
      greeting: 'નમસ્તે... હું તમારી સ્મૃતિ સાથી છું. તમારી સાથે રહીને મને ઘણો આનંદ થાય છે.',
      phoneticGreeting: 'Namaste... Hu tamaari Smriti Saathi chhu. Tamaari saathe rahine mane ghano aanand thaay chhe.',
      ttsLocale: 'gu-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'ਪੰਜਾਬੀ',
      nativeName: 'ਪੰਜਾਬੀ',
      englishName: 'Punjabi',
      region: 'Punjab',
      greeting: 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ... ਮੈਂ ਤੁਹਾਡਾ ਸਾਥੀ ਸਮ੍ਰਿਤੀ ਸਾਥੀ ਹਾਂ। ਤੁਹਾਡੇ ਨਾਲ ਹੋ ਕੇ ਮੈਨੂੰ ਬਹੁਤ ਖੁਸ਼ੀ ਹੈ।',
      phoneticGreeting: 'Sat sri akaal... Main tuhaada saathi Smriti Saathi haan. Tuhaade naal ho ke mainu bahut khushi hai.',
      ttsLocale: 'pa-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'ଓଡ଼ିଆ',
      nativeName: 'ଓଡ଼ିଆ',
      englishName: 'Odia',
      region: 'Odisha',
      greeting: 'ନମସ୍କାର... ମୁଁ ଆପଣଙ୍କ ସ୍ମୃତି ସାଥୀ। ଆପଣଙ୍କ ସହିତ ରହି ମୁଁ ବହୁତ ଖୁସି।',
      phoneticGreeting: 'Namaskar... Mu aapankara Smriti Saathi. Aapankara sahita rahi mu bahut khusi.',
      ttsLocale: 'or-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'অসমীয়া',
      nativeName: 'অসমীয়া',
      englishName: 'Assamese',
      region: 'Assam & North East',
      greeting: 'নমস্কাৰ... মই আপোনাৰ সংগী স্মৃতি সাথী। আপোনাৰ কাষত থাকিবলৈ পাই মই অতি আনন্দিত।',
      phoneticGreeting: 'Nomoskar... Moi aapunar songi Smriti Saathi. Aapunar kaakhot thaakibole paai moi oti aanondito.',
      ttsLocale: 'as-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'মৈতৈলোন্',
      nativeName: 'মৈতৈলোন্',
      englishName: 'Manipuri (Meitei)',
      region: 'Manipur',
      greeting: 'খুরুমজরি... ঐহাক নখোইগী সাথীনি। নখোইগী লোয়ননা লৈবদা য়াম্না নুংঙাই।',
      phoneticGreeting: 'Khurumjari... Eihak nahakki Saathini. Nahakki loyanna leibada yamna nungai.',
      ttsLocale: 'mni-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'Mizo',
      nativeName: 'Mizo ṭawng',
      englishName: 'Mizo',
      region: 'Mizoram',
      greeting: 'Chibai... Kei hi i Saathi ka ni e. I kianga awm hi ka lawm hle mai.',
      phoneticGreeting: 'Chibai... Kei hi i Saathi ka ni e. I kianga awm hi ka lawm hle mai.',
      ttsLocale: 'en-IN',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      id: 'नेपाली',
      nativeName: 'नेपाली',
      englishName: 'Nepali',
      region: 'Sikkim, Assam & Hills',
      greeting: 'नमस्ते... म तपाईंको साथी स्मृति साथी हुँ। तपाईंसँग हुन पाउँदा मलाई धेरै खुसी लागेको छ।',
      phoneticGreeting: 'Namaste... Ma tapaaiko saathi Smriti Saathi hoon. Tapaaisanga huna paaudaa malai dherai khusi laageko chha.',
      ttsLocale: 'ne-NP',
      flag: '🇮🇳',
    ),
  ];

  static LanguageInfo getLanguageInfo(String languageName) {
    for (final l in supportedLanguages) {
      if (l.id == languageName ||
          l.nativeName == languageName ||
          l.englishName.toLowerCase() == languageName.toLowerCase() ||
          languageName.toLowerCase().contains(l.englishName.toLowerCase()) ||
          l.englishName.toLowerCase().contains(languageName.toLowerCase())) {
        return l;
      }
    }
    return supportedLanguages.first;
  }

  /// Selects the ideal typography font designed specifically for each regional script
  static TextStyle getFont(
    String language, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final langLower = language.toLowerCase();
    // Tamil
    if (langLower.contains('tamil') || langLower.contains('தமிழ்')) {
      return GoogleFonts.notoSansTamil(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    // Telugu
    if (langLower.contains('telugu') || langLower.contains('తెలుగు')) {
      return GoogleFonts.notoSansTelugu(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    // Kannada
    if (langLower.contains('kannada') || langLower.contains('ಕನ್ನಡ')) {
      return GoogleFonts.notoSansKannada(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    // Malayalam
    if (langLower.contains('malayalam') || langLower.contains('മലയാളം')) {
      return GoogleFonts.notoSansMalayalam(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    // Gujarati
    if (langLower.contains('gujarati') || langLower.contains('ગુજરાતી')) {
      return GoogleFonts.notoSansGujarati(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    // Punjabi
    if (langLower.contains('punjabi') || langLower.contains('ਪੰਜਾਬੀ')) {
      return GoogleFonts.notoSansGurmukhi(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    // Odia
    if (langLower.contains('odia') || langLower.contains('oriya') || langLower.contains('ଓଡ଼ିଆ')) {
      return GoogleFonts.notoSansOriya(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    // Eastern Nagari script for Assamese, Bengali, Manipuri
    if (langLower.contains('assamese') ||
        langLower.contains('অসমীয়া') ||
        langLower.contains('bengali') ||
        langLower.contains('বাংলা') ||
        langLower.contains('manipuri') ||
        langLower.contains('meitei') ||
        langLower.contains('মৈতৈ')) {
      return GoogleFonts.hindSiliguri(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    // Devanagari script for Hindi, Marathi, Nepali
    else if (langLower.contains('hindi') ||
        langLower.contains('हिंदी') ||
        langLower.contains('हिन्दी') ||
        langLower.contains('marathi') ||
        langLower.contains('मराठी') ||
        langLower.contains('nepali') ||
        langLower.contains('नेपाली')) {
      return GoogleFonts.hind(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    // Modern Latin typography for English & Mizo
    else {
      return GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
  }

  static const Map<String, AppTranslationData> _data = {
    'English': AppTranslationData(
      languageName: 'English',
      modalTitle: 'Choose Your Language',
      modalSubtitle: 'Smriti Saathi will adapt to your preferred language with voice & comfort.',
      editionBadge: 'North-East India & National Edition',
      confirmButton: 'Confirm & Continue',
      skipButton: 'Skip',
      backButton: 'Back',
      continueButton: 'Continue',
      getStartedButton: 'Get Started',
      mottoBanner: 'Because every memory matters...',
      footerTrust: 'Simple to use  •  Made with care  •  100% Private',
      slides: [
        OnboardingSlideTranslation(
          label: 'YOUR AI COMPANION',
          title: 'Smriti Saathi',
          motto: 'Your AI Saathi for Everyday Life & Memories',
          description:
              'A patient, loving companion that listens with warmth, preserves your precious memories, and keeps you close to the people and stories that matter most.',
          tags: ['Voice-First', 'Cherished Memories', '100% Private'],
        ),
        OnboardingSlideTranslation(
          label: 'VOICE FIRST',
          title: 'Just Talk.\nSaathi Listens.',
          motto: 'Speak naturally, in your comfortable language',
          description:
              'Tap the large microphone and speak freely. Saathi listens with infinite patience, warmth, and care — never rushing you.',
          tags: ['Speaks Your Language', 'Calm & Patient', 'Zero Complex Menus'],
        ),
        OnboardingSlideTranslation(
          label: 'CHERISHED MEMORIES',
          title: 'Keep Memories\nSafe & Close',
          motto: 'Preserving precious family heritage & smiles',
          description:
              'Preserve family photos, voice stories, familiar faces, and special dates in a calm, joyful sanctuary.',
          tags: ['Family Faces', 'Voice Stories', 'Special Dates'],
        ),
        OnboardingSlideTranslation(
          label: 'ALWAYS AVAILABLE',
          title: 'Always With You,\nEven Offline',
          motto: 'Works reliably anytime, anywhere',
          description:
              'All your core features work completely offline without internet. Your personal memories and routines stay 100% safe and private.',
          tags: ['Works Offline', 'Zero Tracking', 'Caregiver Connected'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'Home',
        voiceSaathi: 'Voice Saathi',
        memories: 'Memories',
        activities: 'Activities',
        family: 'Family',
        askSaathi: 'Ask Saathi',
      ),
      home: HomeTranslation(
        greetingMorning: 'Good morning',
        greetingAfternoon: 'Good afternoon',
        greetingEvening: 'Good evening',
        saathiReady: 'Smriti Saathi is ready',
        feelingQuestion: 'How are you feeling right now?',
        happy: 'Happy',
        peaceful: 'Peaceful',
        thoughtful: 'Thoughtful',
        resting: 'Resting',
        talkHeroTitle: 'Just talk. Saathi listens.',
        talkHeroSubtitle: 'Share a story, ask for assistance, or just say hello.',
        tapToSpeak: 'Tap to Speak',
      ),
    ),

    'தமிழ்': AppTranslationData(
      languageName: 'தமிழ்',
      modalTitle: 'உங்கள் மொழியைத் தேர்வுசெய்யவும்',
      modalSubtitle: 'ஸ்மிருதி சாதி உங்கள் தாய்மொழியில் அன்போடும் கனிவோடும் பேசும்.',
      editionBadge: 'வடகிழக்கு இந்தியா மற்றும் தேசிய பதிப்பு',
      confirmButton: 'உறுதிசெய்து தொடரவும்',
      skipButton: 'தவிர்',
      backButton: 'பின்செல்',
      continueButton: 'தொடரவும்',
      getStartedButton: 'தொடங்குங்கள்',
      mottoBanner: 'ஒவ்வொரு நினைவும் பொக்கிஷம்...',
      footerTrust: 'பயன்படுத்த எளிது  •  அன்புடன் உருவாக்கப்பட்டது  •  100% பாதுகாப்பானது',
      slides: [
        OnboardingSlideTranslation(
          label: 'உங்கள் AI தோழன்',
          title: 'ஸ்மிருதி சாதி',
          motto: 'அன்றாட வாழ்வு மற்றும் நினைவுகளுக்கான உங்கள் AI சாதி',
          description:
              'கனிவோடு செவிசாய்த்து, உங்கள் இனிய நினைவுகளைப் பாதுகாத்து, உங்களுக்குப் பிரியமானவர்களோடு உங்களை இணைக்கும் பாசமிகு தோழன்.',
          tags: ['குரல் வழி பயன்பாடு', 'பொக்கிஷ நினைவுகள்', '100% தனிப்பட்டவை'],
        ),
        OnboardingSlideTranslation(
          label: 'குரல் வழி முதலில்',
          title: 'பேசுங்கள் மட்டும்.\nசாதி கேட்கிறது.',
          motto: 'உங்கள் விருப்பமான மொழியில் இயல்பாகப் பேசுங்கள்',
          description:
              'பெரிய மைக் பட்டனைத் தட்டி தயக்கமின்றிப் பேசுங்கள். சாதி எல்லையற்ற பொறுமையோடும் அன்போடும் கேட்கும் — அவசரப்படுத்தாது.',
          tags: ['உங்கள் மொழியைப் பேசும்', 'அமைதியானது', 'சிக்கலான மெனுக்கள் இல்லை'],
        ),
        OnboardingSlideTranslation(
          label: 'பொக்கிஷ நினைவுகள்',
          title: 'நினைவுகளைப் பாதுகாப்பாக\nஅருகில் வையுங்கள்',
          motto: 'குடும்ப மகிழ்ச்சியையும் புன்னகையையும் காத்தல்',
          description:
              'குடும்ப புகைப்படங்கள், குரல் கதைகள், அறிமுகமான முகங்கள் மற்றும் முக்கிய தினங்களை பாதுகாப்பான ஓரிடத்தில் சேமியுங்கள்.',
          tags: ['குடும்ப முகங்கள்', 'குரல் கதைகள்', 'முக்கிய தேதிகள்'],
        ),
        OnboardingSlideTranslation(
          label: 'எப்போதும் உடன் இருக்கும்',
          title: 'எப்போதும் உங்களுடன்,\nஆஃப்லைனிலும் கூட',
          motto: 'இணையம் இன்றியும் எப்போதும் உதவ தயார்',
          description:
              'முக்கிய சேவைகள் இணைய இணைப்பு இல்லாமலும் செயல்படும். உங்கள் தனிப்பட்ட நினைவுகள் மற்றும் நடைமுறைகள் முழுமையாகப் பாதுகாக்கப்படும்.',
          tags: ['ஆஃப்லைனில் இயங்கும்', 'முழு பாதுகாப்பு', 'பராமரிப்பாளருடன் இணைப்பு'],
        ),
      ],
      auth: AuthScreenTranslation(
        portalTitle: 'போர்டல் உள்நுழைவு & அணுகல்',
        portalSubtitle: 'பராமரிப்பு, நினைவுகள் மற்றும் அன்றாட நடைமுறைகளை நிர்வகியுங்கள்.',
        howToContinue: 'எவ்வாறு தொடர விரும்புகிறீர்கள்?',
        logIn: 'உள்நுழைக',
        signUp: 'பதிவுசெய்க',
        emailOrPhone: 'மின்னஞ்சல் அல்லது தொலைபேசி',
        demoLogin: 'டெமோ உள்நுழைவு',
        emailHint: 'உதாரணம்: meena.care@gmail.com',
        passwordLabel: 'பின் (PIN) அல்லது கடவுச்சொல்',
        passwordHint: 'உங்கள் கடவுச்சொல் அல்லது 4-இலக்க பின்னை உள்ளிடவும்',
        showPassword: 'கடவுச்சொல்லைக் காட்டு',
        hidePassword: 'கடவுச்சொல்லை மறை',
        logInAsCaretaker: 'பராமரிப்பாளராக உள்நுழைக',
        newCaretakerLink: 'புதிய பராமரிப்பாளரா? கணக்கு தொடங்கவும்',
        yourFullName: 'உங்கள் முழுப் பெயர்',
        demoAutofill: 'டெமோ தானியங்கி நிரப்பு',
        relationshipToPatient: 'உறவுமுறை',
        phoneAndEmail: 'தொலைபேசி மற்றும் மின்னஞ்சல்',
        phoneHint: '+91 98450 12345',
        emailHintSignup: 'meena@gmail.com',
        createCaretakerAccount: 'பராமரிப்பாளர் கணக்கை உருவாக்கு',
        seniorCompanionLabel: 'முதியோர் தோழமைக்காக',
        enterAsSenior: 'முதியவராக நுழைக',
        enterAsSeniorSubtitle: 'குடும்பத்தினர் வழங்கிய பாஸ்கீயைப் பயன்படுத்தவும் அல்லது விருந்தினர் பயன்முறையைத் தேர்ந்தெடுக்கவும்.',
        passKeyHint: 'பாஸ்கீயை உள்ளிடவும் (எ.கா. SAATHI-7821)',
        startSeniorCompanion: 'தோழமையைத் தொடங்கு',
        orSelectActiveSenior: 'அல்லது செயலில் உள்ள முதியவரைத் தேர்வுசெய்க',
        passKeyLabel: 'பாஸ்கீ',
        instantGuestLogin: 'உடனடி விருந்தினர் / டெமோ உள்நுழைவு',
        emailEmptyError: 'மின்னஞ்சல் அல்லது தொலைபேசியை உள்ளிடவும்',
        nameEmptyError: 'உங்கள் முழுப் பெயரை உள்ளிடவும்',
        passKeyEmptyError: 'பாஸ்கீ அல்லது குறியீட்டை உள்ளிடவும்',
        passKeyNotFoundError: 'பாஸ்கீ காணப்படவில்லை. DEMO முயலவும்.',
      ),
      nav: ShellTranslation(
        home: 'முகப்பு',
        voiceSaathi: 'குரல் சாதி',
        memories: 'நினைவுகள்',
        activities: 'செயல்பாடுகள்',
        family: 'குடும்பம்',
        askSaathi: 'சாதியிடம் கேளுங்கள்',
      ),
      home: HomeTranslation(
        greetingMorning: 'காலை வணக்கம்',
        greetingAfternoon: 'மதிய வணக்கம்',
        greetingEvening: 'மாலை வணக்கம்',
        saathiReady: 'ஸ்மிருதி சாதி தயாராக உள்ளது',
        feelingQuestion: 'இப்போது உங்கள் மனம் எப்படி இருக்கிறது?',
        happy: 'மகிழ்ச்சி',
        peaceful: 'அமைதி',
        thoughtful: 'சிந்தனை',
        resting: 'ஓய்வு',
        talkHeroTitle: 'பேசுங்கள். சாதி கேட்கிறது.',
        talkHeroSubtitle: 'ஒரு கதையைப் பகிருங்கள், உதவி கேளுங்கள் அல்லது ஒரு வணக்கம் சொல்லுங்கள்.',
        tapToSpeak: 'பேசத் தட்டவும்',
      ),
    ),

    'हिन्दी': AppTranslationData(
      languageName: 'हिन्दी',
      modalTitle: 'अपनी भाषा चुनें',
      modalSubtitle: 'स्मृति साथी आपकी पसंदीदा भाषा में आवाज़ और प्यार के साथ साथ देगा।',
      editionBadge: 'पूर्वोत्तर भारत और राष्ट्रीय संस्करण',
      confirmButton: 'पुष्टि करें और आगे बढ़ें',
      skipButton: 'छोड़ें',
      backButton: 'पीछे',
      continueButton: 'आगे बढ़ें',
      getStartedButton: 'शुरू करें',
      mottoBanner: 'क्योंकि हर याद अनमोल है...',
      footerTrust: 'उपयोग में सरल  •  प्यार से निर्मित  •  100% सुरक्षित एवं निजी',
      slides: [
        OnboardingSlideTranslation(
          label: 'आपका AI साथी',
          title: 'स्मृति साथी',
          motto: 'दैनिक जीवन और अनमोल यादों के लिए आपका AI साथी',
          description:
              'एक धैर्यवान, स्नेही साथी जो आपकी बात प्रेम से सुनता है, आपकी सुंदर यादों को सहेजता है और आपको अपनों के करीब रखता है।',
          tags: ['आवाज़-आधारित', 'अनमोल यादें', '100% सुरक्षित'],
        ),
        OnboardingSlideTranslation(
          label: 'आवाज़ पहले',
          title: 'बस बात करें।\nसाथी सुनता है।',
          motto: 'अपनी मातृभाषा में सहजता से बात करें',
          description:
              'बड़े माइक बटन को दबाएं और दिल खोलकर बात करें। साथी बिना जल्दबाजी के अपार धैर्य, स्नेह और संवेदनशीलता से सुनता है।',
          tags: ['आपकी भाषा बोलता है', 'शांत और धैर्यवान', 'कोई उलझन नहीं'],
        ),
        OnboardingSlideTranslation(
          label: 'अनमोल यादें',
          title: 'यादों को सुरक्षित\nऔर पास रखें',
          motto: 'परिवार की पुरानी यादें और मुस्कान सहेजें',
          description:
              'पारिवारिक तस्वीरें, आवाज़ की कहानियाँ, जाने-पहचाने चेहरे और खास तारीखें एक शांत, सुंदर संदूक में सुरक्षित रखें।',
          tags: ['अपनों के चेहरे', 'आवाज़ की कहानियाँ', 'खास तारीखें'],
        ),
        OnboardingSlideTranslation(
          label: 'हमेशा उपलब्ध',
          title: 'हमेशा आपके साथ,\nऑफ़लाइन भी',
          motto: 'बिना इंटरनेट हर समय, हर जगह उपलब्ध',
          description:
              'मुख्य सुविधाएं बिना इंटरनेट भी पूरी तरह काम करती हैं। आपकी निजी यादें और दिनचर्या आपके फोन में पूर्णतः सुरक्षित हैं।',
          tags: ['ऑफ़लाइन काम करता है', 'पूरी तरह गोपनीय', 'देखभालकर्ता से जुड़ा'],
        ),
      ],
      auth: AuthScreenTranslation(
        portalTitle: 'पोर्टल लॉगिन और पहुँच',
        portalSubtitle: 'देखभाल, यादें और दिनचर्या प्रबंधित करें, या बुजुर्ग साथी के रूप में प्रवेश करें।',
        howToContinue: 'आप कैसे आगे बढ़ना चाहेंगे?',
        logIn: 'लॉग इन',
        signUp: 'साइन अप',
        emailOrPhone: 'ईमेल या फ़ोन नंबर',
        demoLogin: 'डेमो लॉगिन',
        emailHint: 'उदा. meena.care@gmail.com',
        passwordLabel: 'पिन या पासवर्ड',
        passwordHint: 'अपना पासवर्ड या 4-अंकों का पिन दर्ज करें',
        showPassword: 'पासवर्ड दिखाएं',
        hidePassword: 'पासवर्ड छिपाएं',
        logInAsCaretaker: 'देखभालकर्ता के रूप में लॉगिन करें',
        newCaretakerLink: 'नए देखभालकर्ता? यहाँ खाता बनाएं',
        yourFullName: 'आपका पूरा नाम',
        demoAutofill: 'डेमो ऑटो-फिल',
        relationshipToPatient: 'मरीज़ से संबंध',
        phoneAndEmail: 'फ़ोन और ईमेल',
        phoneHint: '+91 98450 12345',
        emailHintSignup: 'meena@gmail.com',
        createCaretakerAccount: 'देखभालकर्ता खाता बनाएं',
        seniorCompanionLabel: 'बुजुर्ग साथी के लिए',
        enterAsSenior: 'बुजुर्ग साथी के रूप में प्रवेश',
        enterAsSeniorSubtitle: 'अपने परिवार द्वारा दिया गया पास-की दर्ज करें, या गेस्ट मोड चुनें।',
        passKeyHint: 'पास-की दर्ज करें (जैसे SAATHI-7821)',
        startSeniorCompanion: 'साथी शुरू करें',
        orSelectActiveSenior: 'या सक्रिय साथी चुनें',
        passKeyLabel: 'पास-की',
        instantGuestLogin: 'त्वरित गेस्ट / डेमो लॉगिन',
        emailEmptyError: 'कृपया ईमेल या फ़ोन नंबर दर्ज करें',
        nameEmptyError: 'कृपया अपना पूरा नाम दर्ज करें',
        passKeyEmptyError: 'कृपया पास-की दर्ज करें',
        passKeyNotFoundError: 'पास-की नहीं मिली। DEMO आज़माएं।',
      ),
      nav: ShellTranslation(
        home: 'होम',
        voiceSaathi: 'आवाज़ साथी',
        memories: 'यादें',
        activities: 'गतिविधियां',
        family: 'परिवार',
        askSaathi: 'साथी से पूछें',
      ),
      home: HomeTranslation(
        greetingMorning: 'शुभ प्रभात',
        greetingAfternoon: 'शुभ दोपहर',
        greetingEvening: 'शुभ संध्या',
        saathiReady: 'स्मृति साथी तैयार है',
        feelingQuestion: 'आज आप कैसा महसूस कर रहे हैं?',
        happy: 'खुश',
        peaceful: 'शांत',
        thoughtful: 'विचारशील',
        resting: 'आराम में',
        talkHeroTitle: 'बस बोलिए। साथी सुन रहा है।',
        talkHeroSubtitle: 'कोई किस्सा सुनाइए, सवाल पूछिए या केवल नमस्कार कहिए।',
        tapToSpeak: 'बोलने के लिए दबाएं',
      ),
    ),

    'తెలుగు': AppTranslationData(
      languageName: 'తెలుగు',
      modalTitle: 'మీ భాషను ఎంచుకోండి',
      modalSubtitle: 'స్మృతి సాథి మీతో ప్రేమగా, ఆత్మీయంగా మీ సొంత భాషలోనే మాట్లాడుతుంది.',
      editionBadge: 'ఈశాన్య భారతదేశం మరియు జాతీయ ఎడిషన్',
      confirmButton: 'నిర్ధారించి కొనసాగించండి',
      skipButton: 'దాటవేయి',
      backButton: 'వెనుకకు',
      continueButton: 'కొనసాగించండి',
      getStartedButton: 'ప్రారంభించండి',
      mottoBanner: 'ప్రతి జ్ఞాపకం ఎంతో అమూల్యమైనది...',
      footerTrust: 'వాడటం సులభం  •  ప్రేమతో రూపొందించబడింది  •  100% గోప్యత',
      slides: [
        OnboardingSlideTranslation(
          label: 'మీ AI స్నేహితుడు',
          title: 'స్మృతి సాథి',
          motto: 'రోజువారీ జీవితం మరియు మధుర జ్ఞాపకాల కోసం మీ AI సాథి',
          description:
              'ఓర్పుతో మీ మాటలు వింటూ, మధుర జ్ఞాపకాలను భద్రపరుస్తూ, మీకు ఇష్టమైన వారికి మిమ్మల్ని చేరువగా ఉంచే ఆత్మీయ నేస్తం.',
          tags: ['వాయిస్ ప్రాధాన్యత', 'మధుర జ్ఞాపకాలు', '100% సురక్షితం'],
        ),
        OnboardingSlideTranslation(
          label: 'వాయిస్ ఫస్ట్',
          title: 'మాట్లాడండి చాలు.\nసాథి వింటుంది.',
          motto: 'మీకు అనువైన భాషలో స్వేచ్ఛగా మాట్లాడండి',
          description:
              'పెద్ద మైక్ బటన్‌ను నొక్కి హాయిగా మాట్లాడండి. సాథి అపారమైన ఓర్పు మరియు ఆప్యాయతతో వింటుంది.',
          tags: ['మీ భాష మాట్లాడుతుంది', 'ప్రశాంతత', 'సులభమైన విధానం'],
        ),
        OnboardingSlideTranslation(
          label: 'అమూల్య జ్ఞాపకాలు',
          title: 'జ్ఞాపకాలను భద్రంగా\nదగ్గరగా ఉంచండి',
          motto: 'కుటుంబ సంతోషాలు మరియు చిరునవ్వుల సంరక్షణ',
          description:
              'కుటుంబ ఫోటోలు, గొంతు కథలు, పరిచయస్తుల ముఖాలు మరియు ముఖ్యమైన రోజులను సురక్షితంగా దాచుకోండి.',
          tags: ['కుటుంబ ముఖాలు', 'వాయిస్ కథలు', 'ముఖ్యమైన తేదీలు'],
        ),
        OnboardingSlideTranslation(
          label: 'ఎల్లప్పుడూ మీతో',
          title: 'ఎల్లవేళలా మీతోనే,\nఆఫ్‌లైన్‌లో కూడా',
          motto: 'ఇంటర్నెట్ లేకపోయినా ఎల్లప్పుడూ తోడుగా',
          description:
              'ముఖ్యమైన ఫీచర్లు ఇంటర్నెట్ లేకుండా కూడా పనిచేస్తాయి. మీ వ్యక్తిగత జ్ఞాపకాలు పూర్తి సురక్షితం.',
          tags: ['ఆఫ్‌లైన్ పనితీరు', 'పూర్తి భద్రత', 'సంరక్షకుని అనుసంధానం'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'హోమ్',
        voiceSaathi: 'వాయిస్ సాథి',
        memories: 'జ్ఞాపకాలు',
        activities: 'కార్యకలాపాలు',
        family: 'కుటుంబం',
        askSaathi: 'సాథిని అడగండి',
      ),
      home: HomeTranslation(
        greetingMorning: 'శుభోదయం',
        greetingAfternoon: 'శుభ మధ్యాహ్నం',
        greetingEvening: 'శుభ సాయంత్రం',
        saathiReady: 'స్మృతి సాథి సిద్ధంగా ఉంది',
        feelingQuestion: 'ఇప్పుడు మీరు ఎలా భావిస్తున్నారు?',
        happy: 'సంతోషం',
        peaceful: 'ప్రశాంతం',
        thoughtful: 'ఆలోచన',
        resting: 'విశ్రాంతి',
        talkHeroTitle: 'మాట్లాడండి. సాథి వింటుంది.',
        talkHeroSubtitle: 'కబుర్లు చెప్పండి, సాయం కోరండి లేదా పలకరించండి.',
        tapToSpeak: 'మాట్లాడటానికి నొక్కండి',
      ),
    ),

    'ಕನ್ನಡ': AppTranslationData(
      languageName: 'ಕನ್ನಡ',
      modalTitle: 'ನಿಮ್ಮ ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
      modalSubtitle: 'ಸ್ಮೃತಿ ಸಾಥಿ ನಿಮ್ಮೊಂದಿಗೆ ಪ್ರೀತಿಯಿಂದ, ಸೌಹಾರ್ದತೆಯಿಂದ ಸಂಭಾಷಿಸುತ್ತದೆ.',
      editionBadge: 'ಈಶಾನ್ಯ ಭಾರತ ಮತ್ತು ರಾಷ್ಟ್ರೀಯ ಆವೃತ್ತಿ',
      confirmButton: 'ದೃಢೀಕರಿಸಿ ಮುಂದುವರಿಯಿರಿ',
      skipButton: 'ಬಿಟ್ಟುಬಿಡಿ',
      backButton: 'ಹಿಂದೆ',
      continueButton: 'ಮುಂದುವರಿಯಿರಿ',
      getStartedButton: 'ಪ್ರಾರಂಭಿಸಿ',
      mottoBanner: 'ಪ್ರತಿಯೊಂದು ನೆನಪೂ ಅಮೂಲ್ಯ...',
      footerTrust: 'ಬಳಸಲು ಸುಲಭ  •  ಪ್ರೀತಿಯಿಂದ ನಿರ್ಮಿತ  •  100% ಸುರಕ್ಷಿತ',
      slides: [
        OnboardingSlideTranslation(
          label: 'ನಿಮ್ಮ AI ಒಡನಾಡಿ',
          title: 'ಸ್ಮೃತಿ ಸಾಥಿ',
          motto: 'ದೈನಂದಿನ ಜೀವನ ಮತ್ತು ನೆನಪುಗಳಿಗಾಗಿ ನಿಮ್ಮ AI ಸಾಥಿ',
          description:
              'ತಾಳ್ಮೆಯಿಂದ ನಿಮ್ಮ ಮಾತುಗಳನ್ನು ಆಲಿಸುವ, ಸುಂದರ ನೆನಪುಗಳನ್ನು ಕಾಪಾಡುವ ಮತ್ತು ನಿಮ್ಮವರೊಂದಿಗೆ ನಿಕಟವಾಗಿರಿಸುವ ಆಪ್ತ ಮಿತ್ರ.',
          tags: ['ಧ್ವನಿ-ಆಧಾರಿತ', 'ಅಮೂಲ್ಯ ನೆನಪುಗಳು', '100% ಗೌಪ್ಯತೆ'],
        ),
        OnboardingSlideTranslation(
          label: 'ಧ್ವನಿ ಮೊದಲು',
          title: 'ಮಾತನಾಡಿ ಸಾಕು.\nಸಾಥಿ ಕೇಳಿಸಿಕೊಳ್ಳುತ್ತದೆ.',
          motto: 'ನಿಮ್ಮ ಆಪ್ತ ಭಾಷೆಯಲ್ಲಿ ಸರಳವಾಗಿ ಮಾತನಾಡಿ',
          description:
              'ದೊಡ್ಡ ಮೈಕ್ ಬಟನ್ ಒತ್ತಿ ಮುಕ್ತವಾಗಿ ಮಾತನಾಡಿ. ಸಾಥಿ ಪ್ರೀತಿ ಮತ್ತು ತಾಳ್ಮೆಯಿಂದ ಆಲಿಸುತ್ತದೆ.',
          tags: ['ನಿಮ್ಮ ಭಾಷೆ ತಿಳಿಯುತ್ತದೆ', 'ಶಾಂತ ಮತ್ತು ತಾಳ್ಮೆ', 'ಸುಲಭ ಬಳಕೆ'],
        ),
        OnboardingSlideTranslation(
          label: 'ಮಧುರ ನೆನಪುಗಳು',
          title: 'ನೆನಪುಗಳನ್ನು ಸುರಕ್ಷಿತವಾಗಿ\nಹತ್ತಿರ ಇರಿಸಿ',
          motto: 'ಕುಟುಂಬದ ಸಂತೋಷ ಮತ್ತು ನಗೆಯ ರಕ್ಷಣೆ',
          description:
              'ಕುಟುಂಬದ ಫೋಟೋಗಳು, ಧ್ವನಿ ಕಥೆಗಳು, ಪರಿಚಿತ ಮುಖಗಳು ಮತ್ತು ವಿಶೇಷ ದಿನಗಳನ್ನು ಭದ್ರವಾಗಿ ಉಳಿಸಿ.',
          tags: ['ಕುಟುಂಬದ ಮುಖಗಳು', 'ಧ್ವನಿ ಕಥೆಗಳು', 'ವಿಶೇಷ ದಿನಗಳು'],
        ),
        OnboardingSlideTranslation(
          label: 'ಯಾವಾಗಲೂ ಲಭ್ಯ',
          title: 'ಯಾವಾಗಲೂ ನಿಮ್ಮೊಂದಿಗೆ,\nಆಫ್‌ಲೈನ್‌ನಲ್ಲೂ ಸಹ',
          motto: 'ಇಂಟರ್ನೆಟ್ ಇಲ್ಲದೆಯೂ ಯಾವುದೇ ಸಮಯದಲ್ಲಿ ಲಭ್ಯ',
          description:
              'ಪ್ರಮುಖ ವೈಶಿಷ್ಟ್ಯಗಳು ಇಂಟರ್ನೆಟ್ ಇಲ್ಲದೆಯೂ ಕಾರ್ಯನಿರ್ವಹಿಸುತ್ತವೆ. ನಿಮ್ಮ ಖಾಸಗಿ ನೆನಪುಗಳು ಸಂಪೂರ್ಣ ಸುರಕ್ಷಿತ.',
          tags: ['ಆಫ್‌ಲೈನ್ ಬೆಂಬಲ', 'ಸಂಪೂರ್ಣ ಗೌಪ್ಯತೆ', 'ಆರೈಕೆದಾರರೊಂದಿಗೆ ಸಂಪರ್ಕ'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'ಮುಖಪುಟ',
        voiceSaathi: 'ಧ್ವನಿ ಸಾಥಿ',
        memories: 'ನೆನಪುಗಳು',
        activities: 'ಚಟುವಟಿಕೆಗಳು',
        family: 'ಕುಟುಂಬ',
        askSaathi: 'ಸಾಥಿಯನ್ನು ಕೇಳಿ',
      ),
      home: HomeTranslation(
        greetingMorning: 'ಶುಭೋದಯ',
        greetingAfternoon: 'ಶುಭ ಮಧ್ಯಾಹ್ನ',
        greetingEvening: 'ಶುಭ ಸಂಜೆ',
        saathiReady: 'ಸ್ಮೃತಿ ಸಾಥಿ ಸಿದ್ಧವಾಗಿದೆ',
        feelingQuestion: 'ನೀವು ಈಗ ಹೇಗೆ ಭಾವಿಸುತ್ತಿದ್ದೀರಿ?',
        happy: 'ಖುಷಿ',
        peaceful: 'ಶಾಂತ',
        thoughtful: 'ಚಿಂತನಶೀಲ',
        resting: 'ವಿಶ್ರಾಂತಿ',
        talkHeroTitle: 'ಮಾತನಾಡಿ. ಸಾಥಿ ಕೇಳುತ್ತಿದೆ.',
        talkHeroSubtitle: 'ಕಥೆ ಹಂಚಿಕೊಳ್ಳಿ, ಸಹಾಯ ಕೇಳಿ ಅಥವಾ ಹಲೋ ಹೇಳಿ.',
        tapToSpeak: 'ಮಾತನಾಡಲು ಸ್ಪರ್ಶಿಸಿ',
      ),
    ),

    'മലയാളം': AppTranslationData(
      languageName: 'മലയാളം',
      modalTitle: 'ഭാഷ തിരഞ്ഞെടുക്കുക',
      modalSubtitle: 'സ്മൃതി സാഥി നിങ്ങളോട് സ്നേഹത്തോടെയും ആദരവോടെയും സംസാരിക്കും.',
      editionBadge: 'വടക്കുകിഴക്കൻ ഇന്ത്യയും ദേശീയ പതിപ്പും',
      confirmButton: 'ഉറപ്പാക്കി മുന്നോട്ട് പോകുക',
      skipButton: 'ഒഴിവാക്കുക',
      backButton: 'പുറകിലേക്ക്',
      continueButton: 'തുടരുക',
      getStartedButton: 'ആരംഭിക്കുക',
      mottoBanner: 'ഓരോ ഓർമ്മയും അമൂല്യമാണ്...',
      footerTrust: 'ഉപയോഗിക്കാൻ ലളിതം  •  സ്നേഹത്തോടെ നിർമ്മിച്ചത്  •  100% സുരക്ഷിതം',
      slides: [
        OnboardingSlideTranslation(
          label: 'നിങ്ങളുടെ AI കൂട്ടുകാരൻ',
          title: 'സ്മൃതി സാഥി',
          motto: 'ജീവിതത്തിനും ഓർമ്മകൾക്കുമുള്ള നിങ്ങളുടെ സ്വന്തം AI സാഥി',
          description:
              'ക്ഷമയോടെ കേൾക്കുകയും നല്ല ഓർമ്മകൾ കാത്തുസൂക്ഷിക്കുകയും ചെയ്യുന്ന നിങ്ങളുടെ പ്രിയപ്പെട്ട സ്നേഹിതൻ.',
          tags: ['ശബ്ദ നിയന്ത്രണം', 'പ്രിയ ഓർമ്മകൾ', '100% സ്വകാര്യം'],
        ),
        OnboardingSlideTranslation(
          label: 'വോയ്സ് ഫസ്റ്റ്',
          title: 'സംസാരിക്കൂ.\nസാഥി കേൾക്കുന്നുണ്ട്.',
          motto: 'നിങ്ങളുടെ സ്വന്തം ഭാഷയിൽ സ്വതന്ത്രമായി സംസാരിക്കൂ',
          description:
              'മൈക്ക് ബട്ടൺ അമർത്തി സംസാരിക്കൂ. സാഥി ക്ഷമയോടെയും സ്നേഹത്തോടെയും കേൾക്കും.',
          tags: ['നിങ്ങളുടെ ഭാഷ അറിയാം', 'ശാന്തവും ക്ഷമയുള്ളതും', 'ലളിതം'],
        ),
        OnboardingSlideTranslation(
          label: 'അമൂല്യ ഓർമ്മകൾ',
          title: 'ഓർമ്മകൾ സുരക്ഷിതമായി\nഅടുത്ത് സൂക്ഷിക്കൂ',
          motto: 'കുടുംബ സന്തോഷങ്ങളും പുഞ്ചിരികളും കാത്തുസൂക്ഷിക്കുക',
          description:
              'കുടുംബ ചിത്രങ്ങൾ, ശബ്ദ കഥകൾ, പ്രിയപ്പെട്ട മുഖങ്ങൾ എന്നിവ സുരക്ഷിതമായി സൂക്ഷിക്കുക.',
          tags: ['കുടുംബ മുഖങ്ങൾ', 'ശബ്ദ കഥകൾ', 'പ്രത്യേക ദിനങ്ങൾ'],
        ),
        OnboardingSlideTranslation(
          label: 'എപ്പോഴും ഒപ്പം',
          title: 'എപ്പോഴും നിങ്ങളുടെ കൂടെ,\nഓഫ്‌ലൈനിലും',
          motto: 'ഇന്റർനെറ്റ് ഇല്ലാതെയും എവിടെയും എപ്പോഴും ലഭ്യം',
          description:
              'പ്രധാന സൗകര്യങ്ങളെല്ലാം ഇന്റർനെറ്റ് ഇല്ലാതെ പ്രവർത്തിക്കും. വിവരങ്ങൾ സുരക്ഷിതമാണ്.',
          tags: ['ഓഫ്‌ലൈൻ പ്രവർത്തനം', 'പൂർണ്ണ സുരക്ഷ', 'കെയർടേക്കറുമായി ബന്ധം'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'ഹോം',
        voiceSaathi: 'വോയ്സ് സാഥി',
        memories: 'ഓർമ്മകൾ',
        activities: 'പ്രവർത്തനങ്ങൾ',
        family: 'കുടുംബം',
        askSaathi: 'സാഥിയോട് ചോദിക്കൂ',
      ),
      home: HomeTranslation(
        greetingMorning: 'സുപ്രഭാതം',
        greetingAfternoon: 'ശുഭ ഉച്ചനേരം',
        greetingEvening: 'ശുഭ സായാഹ്നം',
        saathiReady: 'സ്മൃതി സാഥി തയ്യാറാണ്',
        feelingQuestion: 'ഇപ്പോൾ നിങ്ങളുടെ മനസ്സിന് എങ്ങനെയുണ്ട്?',
        happy: 'സന്തോഷം',
        peaceful: 'ശാന്തം',
        thoughtful: 'ചിന്തയിൽ',
        resting: 'വിശ്രമം',
        talkHeroTitle: 'സംസാരിക്കൂ. സാഥി കേൾക്കുന്നു.',
        talkHeroSubtitle: 'ഒരു കഥ പങ്കിടൂ, സംശയങ്ങൾ ചോദിക്കൂ.',
        tapToSpeak: 'സംസാരിക്കാൻ തൊടുക',
      ),
    ),

    'मराठी': AppTranslationData(
      languageName: 'मराठी',
      modalTitle: 'आपली भाषा निवडा',
      modalSubtitle: 'स्मृती साथी आपल्या मातृभाषेत प्रेमाने आणि आपुलकीने संवाद साधेल.',
      editionBadge: 'ईशान्य भारत आणि राष्ट्रीय आवृत्ती',
      confirmButton: 'निश्चित करा आणि पुढे जा',
      skipButton: 'वगळा',
      backButton: 'मागे',
      continueButton: 'पुढे जा',
      getStartedButton: 'सुरू करा',
      mottoBanner: 'कारण प्रत्येक आठवण अनमोल आहे...',
      footerTrust: 'वापरण्यास सोपे  •  प्रेमाने बनवलेले  •  100% सुरक्षित आणि खाजगी',
      slides: [
        OnboardingSlideTranslation(
          label: 'आपला AI सोबती',
          title: 'स्मृती साथी',
          motto: 'दैनंदिन जीवन आणि आठवणींसाठी आपला AI साथी',
          description:
              'एक संयमी, प्रेमळ सोबती जो आपले म्हणणे आपुलकीने ऐकतो, सुंदर आठवणी जतन करतो आणि आप्तस्वकीयांच्या जवळ ठेवतो.',
          tags: ['आवाज-आधारित', 'अनमोल आठवणी', '100% सुरक्षित'],
        ),
        OnboardingSlideTranslation(
          label: 'आवाज प्रथम',
          title: 'फक्त बोला.\nसाथी ऐकतोय.',
          motto: 'आपल्या सहज भाषेत मनमोकळेपणाने बोला',
          description:
              'मोठे माइक बटण दाबा आणि बोला. साथी कोणतीही घाई न करता अपार संयमाने व प्रेमाने ऐकतो.',
          tags: ['आपली भाषा जाणतो', 'शांत आणि संयमी', 'अतिशय सोपे'],
        ),
        OnboardingSlideTranslation(
          label: 'गोड आठवणी',
          title: 'आठवणी सुरक्षित\nआणि जवळ ठेवा',
          motto: 'कौटुंबिक सुख आणि हास्य जतन करा',
          description:
              'कौटुंबिक छायाचित्रे, आवाजातील गोष्टी, परिचयाचे चेहरे आणि खास तारखा एका सुरक्षित जागी जतन करा.',
          tags: ['आपल्यांचे चेहरे', 'ध्वनी कथा', 'खास तारखा'],
        ),
        OnboardingSlideTranslation(
          label: 'नेहमी उपलब्ध',
          title: 'नेहमी आपल्या सोबत,\nऑफलाइन सुद्धा',
          motto: 'इंटरनेटशिवाय कधीही आणि कुठेही उपलब्ध',
          description:
              'मुख्य वैशिष्ट्ये इंटरनेटशिवाय अखंड काम करतात. आपल्या वैयक्तिक आठवणी पूर्णपणे सुरक्षित राहतात.',
          tags: ['ऑफलाइन कार्य', 'पूर्ण गोपनीयता', 'काळजीवाहूशी जोडलेले'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'मुख्यपृष्ठ',
        voiceSaathi: 'आवाज साथी',
        memories: 'आठवणी',
        activities: 'उपक्रम',
        family: 'कुटुंब',
        askSaathi: 'साथीला विचारा',
      ),
      home: HomeTranslation(
        greetingMorning: 'शुभ प्रभात',
        greetingAfternoon: 'शुभ दुपार',
        greetingEvening: 'शुभ संध्याकाळ',
        saathiReady: 'स्मृती साथी सज्ज आहे',
        feelingQuestion: 'आज तुम्हाला कसे वाटत आहे?',
        happy: 'आनंदी',
        peaceful: 'शांत',
        thoughtful: 'विचारमग्न',
        resting: 'विश्रांतीत',
        talkHeroTitle: 'फक्त बोला. साथी ऐकतोय.',
        talkHeroSubtitle: 'काही सांगा, मदत मागा किंवा फक्त नमस्कार करा.',
        tapToSpeak: 'बोलण्यासाठी टॅप करा',
      ),
    ),

    'বাংলা': AppTranslationData(
      languageName: 'বাংলা',
      modalTitle: 'আপনার ভাষা নির্বাচন করুন',
      modalSubtitle: 'স্মৃতি সাথী আপনার পছন্দের ভাষায় উষ্ণতা ও যত্নের সাথে কথা বলবে।',
      editionBadge: 'উত্তর-পূর্ব ভারত ও জাতীয় সংস্করণ',
      confirmButton: 'নিশ্চিত করে এগিয়ে যান',
      skipButton: 'এড়িয়ে যান',
      backButton: 'পেছনে',
      continueButton: 'এগিয়ে যান',
      getStartedButton: 'শুরু করুন',
      mottoBanner: 'কারণ প্রতিটি স্মৃতিই অমূল্য...',
      footerTrust: 'ব্যবহারে সহজ  •  যত্নে তৈরি  •  ১০০% নিরাপদ ও ব্যক্তিগত',
      slides: [
        OnboardingSlideTranslation(
          label: 'আপনার AI সঙ্গী',
          title: 'স্মৃতি সাথী',
          motto: 'প্রতিদিনের জীবন ও স্মৃতির জন্য আপনার AI সাথী',
          description:
              'একজন ধৈর্যশীল ও স্নেহময় সঙ্গী যে ভালোবাসার সাথে শোনে, অমূল্য স্মৃতি আগলে রাখে এবং প্রিয়জনদের কাছে রাখে।',
          tags: ['ভয়েস-ফার্স্ট', 'অমূল্য স্মৃতি', '১০০% ব্যক্তিগত'],
        ),
        OnboardingSlideTranslation(
          label: 'ভয়েস ফার্স্ট',
          title: 'শুধু বলুন।\nসাথী শুনছে।',
          motto: 'আপনার মাতৃভাষায় স্বাচ্ছন্দ্যে কথা বলুন',
          description:
              'বড় মাইক বোতামে স্পর্শ করে মন খুলে কথা বলুন। সাথী অনন্ত ধৈর্য ও মমতায় শুনবে — কোনো তাড়া নেই।',
          tags: ['আপনার ভাষায় কথা বলে', 'শান্ত ও ধৈর্যশীল', 'সহজ ব্যবহার'],
        ),
        OnboardingSlideTranslation(
          label: 'অমূল্য স্মৃতি',
          title: 'স্মৃতিগুলো রাখুন\nনিরাপদ ও কাছে',
          motto: 'পারিবারিক সুখ ও হাসিমুখ সংরক্ষণ',
          description:
              'পারিবারিক ছবি, কণ্ঠের গল্প, চেনা মুখ ও বিশেষ দিনগুলো একটি শান্ত, সুন্দর স্থানে নিরাপদে সাজিয়ে রাখুন।',
          tags: ['প্রিয় মুখ', 'কণ্ঠের গল্প', 'বিশেষ দিন'],
        ),
        OnboardingSlideTranslation(
          label: 'সর্বদা সাথে',
          title: 'সর্বদা আপনার সাথে,\nঅফলাইনেও',
          motto: 'ইন্টারনেট ছাড়াই যেকোনো সময় পাশে',
          description:
              'সমস্ত মূল বৈশিষ্ট্য ইন্টারনেট ছাড়াই কাজ করে। আপনার ব্যক্তিগত স্মৃতি সম্পূর্ণ নিরাপদ থাকে।',
          tags: ['অফলাইনে কাজ করে', 'সম্পূর্ণ গোপনীয়তা', 'পরিচর্যাকারীর সাথে যুক্ত'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'হোম',
        voiceSaathi: 'ভয়েস সাথী',
        memories: 'স্মৃতি',
        activities: 'কার্যক্রম',
        family: 'পরিবার',
        askSaathi: 'সাথীকে জিজ্ঞেস করুন',
      ),
      home: HomeTranslation(
        greetingMorning: 'সুপ্রভাত',
        greetingAfternoon: 'শুভ দুপুর',
        greetingEvening: 'শুভ সন্ধ্যা',
        saathiReady: 'স্মৃতি সাথী প্রস্তুত',
        feelingQuestion: 'এখন আপনার কেমন লাগছে?',
        happy: 'খুশি',
        peaceful: 'শান্ত',
        thoughtful: 'চিন্তাশীল',
        resting: 'বিশ্রামে',
        talkHeroTitle: 'শুধু বলুন। সাথী শুনছে।',
        talkHeroSubtitle: 'গল্প বলুন, সাহায্য চান অথবা কেবল কুশল বিনিময় করুন।',
        tapToSpeak: 'কথা বলতে স্পর্শ করুন',
      ),
    ),

    'ગુજરાતી': AppTranslationData(
      languageName: 'ગુજરાતી',
      modalTitle: 'તમારી ભાષા પસંદ કરો',
      modalSubtitle: 'સ્મૃતિ સાથી તમારી સાથે પ્રેમપૂર્વક અને હૂંફ સાથે વાતચીત કરશે.',
      editionBadge: 'ઉત્તર-પૂર્વ ભારત અને રાષ્ટ્રીય સંસ્કરણ',
      confirmButton: 'ખાતરી કરો અને આગળ વધો',
      skipButton: 'છોડો',
      backButton: 'પાછળ',
      continueButton: 'આગળ વધો',
      getStartedButton: 'શરૂ કરો',
      mottoBanner: 'કારણ કે દરેક યાદ અનમોલ છે...',
      footerTrust: 'વાપરવામાં સરળ  •  પ્રેમથી નિર્મિત  •  100% સુરક્ષિત',
      slides: [
        OnboardingSlideTranslation(
          label: 'તમારો AI સાથી',
          title: 'સ્મૃતિ સાથી',
          motto: 'રોજિંદા જીવન અને યાદો માટે તમારો AI સાથી',
          description:
              'એક ધીરજવાન અને સ્નેહાળ મિત્ર જે તમારી વાત પ્રેમથી સાંભળે છે અને યાદોને સાચવે છે.',
          tags: ['અવાજ-આધારિત', 'અનમોલ યાદો', '100% સુરક્ષિત'],
        ),
        OnboardingSlideTranslation(
          label: 'અવાજ પહેલા',
          title: 'ફક્ત વાત કરો.\nસાથી સાંભળે છે.',
          motto: 'તમારી અનુકૂળ ભાષામાં મુક્તપણે બોલો',
          description:
              'માઇક બટન દબાવો અને બોલો. સાથી ખૂબ ધીરજ અને સ્નેહથી સાંભળશે.',
          tags: ['તમારી ભાષા સમજે છે', 'શાંત અને ધીરજવાન', 'સરળ ઉપયોગ'],
        ),
        OnboardingSlideTranslation(
          label: 'વહાલી યાદો',
          title: 'યાદોને સુરક્ષિત અને\nનજીક રાખો',
          motto: 'પારિવારિક ખુશીઓ અને સ્મિતનું રક્ષણ',
          description:
              'પરિવારના ફોટા, અવાજની વાર્તાઓ અને ખાસ તારીખો એક સુરક્ષિત જગ્યાએ સાચવો.',
          tags: ['પરિવારના ચહેરા', 'અવાજની વાર્તાઓ', 'ખાસ દિવસો'],
        ),
        OnboardingSlideTranslation(
          label: 'હંમેશા હાજર',
          title: 'હંમેશા તમારી સાથે,\nઑફલાઇન પણ',
          motto: 'ઇન્ટરનેટ વિના ગમે ત્યારે ઉપલબ્ધ',
          description:
              'બધી મુખ્ય સુવિધાઓ ઇન્ટરનેટ વિના કાર્ય કરે છે. તમારી અંગત માહિતી સંપૂર્ણ સુરક્ષિત છે.',
          tags: ['ઑફલાઇન સપોર્ટ', 'સંપૂર્ણ સુરક્ષા', 'કેરટેકર સાથે જોડાણ'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'હોમ',
        voiceSaathi: 'વોઇસ સાથી',
        memories: 'યાદો',
        activities: 'પ્રવૃત્તિઓ',
        family: 'પરિવાર',
        askSaathi: 'સાથીને પૂછો',
      ),
      home: HomeTranslation(
        greetingMorning: 'સુપ્રભાત',
        greetingAfternoon: 'શુભ બપોર',
        greetingEvening: 'શુભ સંધ્યા',
        saathiReady: 'સ્મૃતિ સાથી તૈયાર છે',
        feelingQuestion: 'હવે તમને કેવું લાગે છે?',
        happy: 'આનંદિત',
        peaceful: 'શાંત',
        thoughtful: 'વિચારશીલ',
        resting: 'આરામ',
        talkHeroTitle: 'ફક્ત વાત કરો. સાથી સાંભળે છે.',
        talkHeroSubtitle: 'વાર્તા કહો, મદદ માગો અથવા હલો કહો.',
        tapToSpeak: 'બોલવા માટે દબાવો',
      ),
    ),

    'ਪੰਜਾਬੀ': AppTranslationData(
      languageName: 'ਪੰਜਾਬੀ',
      modalTitle: 'ਆਪਣੀ ਬੋਲੀ ਚੁਣੋ',
      modalSubtitle: 'ਸਮ੍ਰਿਤੀ ਸਾਥੀ ਤੁਹਾਡੇ ਨਾਲ ਪਿਆਰ ਅਤੇ ਸਤਿਕਾਰ ਨਾਲ ਗੱਲ ਕਰੇਗਾ।',
      editionBadge: 'ਉੱਤਰ-ਪੂਰਬੀ ਭਾਰਤ ਅਤੇ ਰਾਸ਼ਟਰੀ ਸੰਸਕਰਨ',
      confirmButton: 'ਪੁਸ਼ਟੀ ਕਰੋ ਅਤੇ ਅੱਗੇ ਵਧੋ',
      skipButton: 'ਛੱਡੋ',
      backButton: 'ਪਿੱਛੇ',
      continueButton: 'ਅੱਗੇ ਵਧੋ',
      getStartedButton: 'ਸ਼ੁਰੂ ਕਰੋ',
      mottoBanner: 'ਕਿਉਂਕਿ ਹਰ ਯਾਦ ਅਨਮੋਲ ਹੈ...',
      footerTrust: 'ਵਰਤੋਂ ਵਿੱਚ ਆਸਾਨ  •  ਪਿਆਰ ਨਾਲ ਬਣਾਇਆ  •  100% ਸੁਰੱਖਿਅਤ',
      slides: [
        OnboardingSlideTranslation(
          label: 'ਤੁਹਾਡਾ AI ਸਾਥੀ',
          title: 'ਸਮ੍ਰਿਤੀ ਸਾਥੀ',
          motto: 'ਰੋਜ਼ਾਨਾ ਜੀਵਨ ਅਤੇ ਮਿੱਠੀਆਂ ਯਾਦਾਂ ਲਈ ਤੁਹਾਡਾ ਸਾਥੀ',
          description:
              'ਇੱਕ ਧੀਰਜਵਾਨ, ਪਿਆਰਾ ਦੋਸਤ ਜੋ ਤੁਹਾਡੀ ਗੱਲ ਧਿਆਨ ਨਾਲ ਸੁਣਦਾ ਹੈ ਅਤੇ ਯਾਦਾਂ ਨੂੰ ਸਾਂਭਦਾ ਹੈ।',
          tags: ['ਆਵਾਜ਼-ਮੁੱਖ', 'ਅਨਮੋਲ ਯਾਦਾਂ', '100% ਨਿੱਜੀ'],
        ),
        OnboardingSlideTranslation(
          label: 'ਆਵਾਜ਼ ਪਹਿਲਾਂ',
          title: 'ਬੱਸ ਗੱਲ ਕਰੋ।\nਸਾਥੀ ਸੁਣ ਰਿਹਾ ਹੈ।',
          motto: 'ਆਪਣੀ ਮਾਂ-ਬੋਲੀ ਵਿੱਚ ਖੁੱਲ੍ਹ ਕੇ ਬੋਲੋ',
          description:
              'ਵੱਡੇ ਮਾਈਕ ਬਟਨ ਨੂੰ ਦਬਾਓ ਅਤੇ ਬੋਲੋ। ਸਾਥੀ ਬਿਨਾਂ ਕਿਸੇ ਕਾਹਲੀ ਦੇ ਪਿਆਰ ਨਾਲ ਸੁਣਦਾ ਹੈ।',
          tags: ['ਤੁਹਾਡੀ ਬੋਲੀ ਸਮਝਦਾ', 'ਸ਼ਾਂਤ ਅਤੇ ਧੀਰਜਵਾਨ', 'ਸੌਖੀ ਵਰਤੋਂ'],
        ),
        OnboardingSlideTranslation(
          label: 'ਮਿੱਠੀਆਂ ਯਾਦਾਂ',
          title: 'ਯਾਦਾਂ ਨੂੰ ਸੁਰੱਖਿਅਤ\nਅਤੇ ਨੇੜੇ ਰੱਖੋ',
          motto: 'ਪਰਿਵਾਰਕ ਖੁਸ਼ੀਆਂ ਅਤੇ ਯਾਦਾਂ ਦੀ ਸੰਭਾਲ',
          description:
              'ਪਰਿਵਾਰਕ ਤਸਵੀਰਾਂ, ਆਵਾਜ਼ ਦੀਆਂ ਕਹਾਣੀਆਂ ਅਤੇ ਖਾਸ ਦਿਨ ਇੱਕ ਥਾਂ ਸਾਂਭ ਕੇ ਰੱਖੋ।',
          tags: ['ਪਰਿਵਾਰ ਦੇ ਚਿਹਰੇ', 'ਆਵਾਜ਼ੀ ਕਹਾਣੀਆਂ', 'ਖਾਸ ਦਿਨ'],
        ),
        OnboardingSlideTranslation(
          label: 'ਹਮੇਸ਼ਾ ਨਾਲ',
          title: 'ਹਮੇਸ਼ਾ ਤੁਹਾਡੇ ਨਾਲ,\nਔਫਲਾਈਨ ਵੀ',
          motto: 'ਇੰਟਰਨੈਟ ਤੋਂ ਬਿਨਾਂ ਵੀ ਹਰ ਸਮੇਂ ਹਾਜ਼ਰ',
          description:
              'ਸਾਰੀਆਂ ਖਾਸ ਸੁਵਿਧਾਵਾਂ ਬਿਨਾਂ ਇੰਟਰਨੈਟ ਦੇ ਕੰਮ ਕਰਦੀਆਂ ਹਨ। ਤੁਹਾਡੀ ਨਿੱਜਤਾ ਪੂਰੀ ਸੁਰੱਖਿਅਤ ਹੈ।',
          tags: ['ਔਫਲਾਈਨ ਚੱਲਦਾ', 'ਪੂਰੀ ਸੁਰੱਖਿਆ', 'ਸੰਭਾਲਕਰਤਾ ਨਾਲ ਜੁੜਿਆ'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'ਮੁੱਖ ਪੰਨਾ',
        voiceSaathi: 'ਆਵਾਜ਼ ਸਾਥੀ',
        memories: 'ਯਾਦਾਂ',
        activities: 'ਸਰਗਰਮੀਆਂ',
        family: 'ਪਰਿਵਾਰ',
        askSaathi: 'ਸਾਥੀ ਨੂੰ ਪੁੱਛੋ',
      ),
      home: HomeTranslation(
        greetingMorning: 'ਸ਼ੁਭ ਸਵੇਰ',
        greetingAfternoon: 'ਸ਼ੁਭ ਦੁਪਹਿਰ',
        greetingEvening: 'ਸ਼ੁਭ ਸ਼ਾਮ',
        saathiReady: 'ਸਮ੍ਰਿਤੀ ਸਾਥੀ ਤਿਆਰ ਹੈ',
        feelingQuestion: 'ਹੁਣ ਤੁਹਾਡਾ ਮਨ ਕਿਹੋ ਜਿਹਾ ਹੈ?',
        happy: 'ਖੁਸ਼',
        peaceful: 'ਸ਼ਾਂਤ',
        thoughtful: 'ਸੋਚਵਾਨ',
        resting: 'ਆਰਾਮ',
        talkHeroTitle: 'ਬੱਸ ਬੋਲੋ। ਸਾਥੀ ਸੁਣ ਰਿਹਾ ਹੈ।',
        talkHeroSubtitle: 'ਕੋਈ ਗੱਲ ਦੱਸੋ, ਮਦਦ ਮੰਗੋ ਜਾਂ ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਕਹੋ।',
        tapToSpeak: 'ਬੋਲਣ ਲਈ ਦਬਾਓ',
      ),
    ),

    'ଓଡ଼ିଆ': AppTranslationData(
      languageName: 'ଓଡ଼ିଆ',
      modalTitle: 'ଆପଣଙ୍କ ଭାଷା ବାଛନ୍ତୁ',
      modalSubtitle: 'ସ୍ମୃତି ସାଥୀ ଆପଣଙ୍କ ସହିତ ସ୍ନେହ ଏବଂ ଶ୍ରଦ୍ଧା ସହିତ କଥାବାର୍ତ୍ତା କରିବ।',
      editionBadge: 'ଉତ୍ତର-ପୂର୍ବ ଭାରତ ଏବଂ ଜାତୀୟ ସଂସ୍କରଣ',
      confirmButton: 'ନିଶ୍ଚିତ କରି ଆଗକୁ ବଢ଼ନ୍ତୁ',
      skipButton: 'ଛାଡ଼ିଦିଅନ୍ତୁ',
      backButton: 'ପଛକୁ',
      continueButton: 'ଆଗକୁ ବଢ଼ନ୍ତୁ',
      getStartedButton: 'ଆରମ୍ଭ କରନ୍ତୁ',
      mottoBanner: 'କାରଣ ପ୍ରତ୍ୟେକ ସ୍ମୃତି ଅମୂଲ୍ୟ...',
      footerTrust: 'ବ୍ୟବହାର କରିବା ସହଜ  •  ସ୍ନେହରେ ନିର୍ମିତ  •  ୧୦୦% ସୁରକ୍ଷିତ',
      slides: [
        OnboardingSlideTranslation(
          label: 'ଆପଣଙ୍କ AI ସାଥୀ',
          title: 'ସ୍ମୃତି ସାଥୀ',
          motto: 'ଦୈନନ୍ଦିନ ଜୀବନ ଏବଂ ସ୍ମୃତି ପାଇଁ ଆପଣଙ୍କ AI ସାଥୀ',
          description:
              'ଜଣେ ଧୈର୍ଯ୍ୟବାନ ଏବଂ ସ୍ନେହୀ ବନ୍ଧୁ ଯିଏ ଶ୍ରଦ୍ଧାର ସହିତ ଶୁଣନ୍ତି ଏବଂ ମଧୁର ସ୍ମୃତିଗୁଡ଼ିକୁ ସାଇତି ରଖନ୍ତି।',
          tags: ['ଭଏସ୍-ପ୍ରାଥମିକତା', 'ଅମୂଲ୍ୟ ସ୍ମୃତି', '୧୦୦% ବ୍ୟକ୍ତିଗତ'],
        ),
        OnboardingSlideTranslation(
          label: 'ଭଏସ୍ ପ୍ରଥମ',
          title: 'କେବଳ କୁହନ୍ତୁ।\nସାଥୀ ଶୁଣୁଛି।',
          motto: 'ଆପଣଙ୍କ ନିଜ ଭାଷାରେ ସହଜରେ କୁହନ୍ତୁ',
          description:
              'ବଡ଼ ମାଇକ୍ ବଟନ୍ ଦବାନ୍ତୁ ଏବଂ କୁହନ୍ତୁ। ସାଥୀ ଧୈର୍ଯ୍ୟ ଓ ପ୍ରେମର ସହିତ ଶୁଣିବ।',
          tags: ['ଆପଣଙ୍କ ଭାଷା ବୁଝେ', 'ଶାନ୍ତ ଏବଂ ଧୈର୍ଯ୍ୟବାନ', 'ସହଜ ବ୍ୟବହାର'],
        ),
        OnboardingSlideTranslation(
          label: 'ମଧୁର ସ୍ମୃତି',
          title: 'ସ୍ମୃତିଗୁଡ଼ିକୁ ସୁରକ୍ଷିତ\nଓ ନିକଟରେ ରଖନ୍ତୁ',
          motto: 'ପାରିବାରିକ ହସଖୁସିର ସୁରକ୍ଷା',
          description:
              'ପାରିବାରିକ ଫଟୋ, କଣ୍ଠ କାହାଣୀ ଏବଂ ବିଶେଷ ତାରିଖଗୁଡ଼ିକୁ ଏକ ସୁରକ୍ଷିତ ସ୍ଥାନରେ ରଖନ୍ତୁ।',
          tags: ['ପରିବାରର ମୁହଁ', 'କଣ୍ଠ କାହାଣୀ', 'ବିଶେଷ ଦିନ'],
        ),
        OnboardingSlideTranslation(
          label: 'ସର୍ବଦା ସହିତ',
          title: 'ସବୁବେଳେ ଆପଣଙ୍କ ସହିତ,\nଅଫଲାଇନ୍ ମଧ୍ୟ',
          motto: 'ଇଣ୍ଟରନେଟ୍ ବିନା ଯେକୌଣସି ସମୟରେ ଉପଲବ୍ଧ',
          description:
              'ସମସ୍ତ ମୁଖ୍ୟ ସୁବିଧା ବିନା ଇଣ୍ଟରନେଟ୍‌ରେ କାର୍ଯ୍ୟ କରେ। ଆପଣଙ୍କ ସ୍ମୃତି ସମ୍ପୂର୍ଣ୍ଣ ସୁରକ୍ଷିତ।',
          tags: ['ଅଫଲାଇନ୍ ସମର୍ଥନ', 'ସମ୍ପୂର୍ଣ୍ଣ ଗୋପନୀୟତା', 'ଯତ୍ନକାରୀଙ୍କ ସହ ଯୋଡ଼ା'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'ମୁଖ୍ୟପୃଷ୍ଠା',
        voiceSaathi: 'ଭଏସ୍ ସାଥୀ',
        memories: 'ସ୍ମୃତି',
        activities: 'କାର୍ଯ୍ୟକଳାପ',
        family: 'ପରିବାର',
        askSaathi: 'ସାଥୀଙ୍କୁ ପଚାରନ୍ତୁ',
      ),
      home: HomeTranslation(
        greetingMorning: 'ଶୁଭ ସକାଳ',
        greetingAfternoon: 'ଶୁଭ ମଧ୍ୟାହ୍ନ',
        greetingEvening: 'ଶୁଭ ସନ୍ଧ୍ୟା',
        saathiReady: 'ସ୍ମୃତି ସାଥୀ ପ୍ରସ୍ତୁତ',
        feelingQuestion: 'ବର୍ତ୍ତମାନ ଆପଣଙ୍କ ମନ କିପରି ଅଛି?',
        happy: 'ଖୁସି',
        peaceful: 'ଶାନ୍ତ',
        thoughtful: 'ଚିନ୍ତନଶୀଳ',
        resting: 'ବିଶ୍ରାମ',
        talkHeroTitle: 'କେବଳ କୁହନ୍ତୁ। ସାଥୀ ଶୁଣୁଛି।',
        talkHeroSubtitle: 'ଗପ କୁହନ୍ତୁ, ସାହାଯ୍ୟ ମାଗନ୍ତୁ କିମ୍ବା ନମସ୍କାର କୁହନ୍ତୁ।',
        tapToSpeak: 'କହିବା ପାଇଁ ଟ୍ୟାପ୍ କରନ୍ତୁ',
      ),
    ),

    'অসমীয়া': AppTranslationData(
      languageName: 'অসমীয়া',
      modalTitle: 'আপোনাৰ ভাষা বাছক',
      modalSubtitle: 'স্মৃতি সাথীয়ে আপোনাৰ নিজৰ ভাষাত মৰম আৰু আপোনত্বৰে সংগ দিব।',
      editionBadge: 'উত্তৰ-পূব ভাৰত আৰু ৰাষ্ট্ৰীয় সংস্কৰণ',
      confirmButton: 'নিশ্চিত কৰি আগবাঢ়ক',
      skipButton: 'বাদ দিয়ক',
      backButton: 'উভতি যাওক',
      continueButton: 'আগবাঢ়ক',
      getStartedButton: 'আৰম্ভ কৰক',
      mottoBanner: 'কাৰণ প্ৰতিটো স্মৃতিয়েই অমূল্য...',
      footerTrust: 'ব্যৱহাৰত সহজ  •  মৰমেৰে নিৰ্মিত  •  ১০০% সুৰক্ষিত আৰু ব্যক্তিগত',
      slides: [
        OnboardingSlideTranslation(
          label: 'আপোনাৰ AI সংগী',
          title: 'স্মৃতি সাথী',
          motto: 'দৈনন্দিন জীৱন আৰু অমূল্য স্মৃতিৰ বাবে আপোনাৰ AI সাথী',
          description:
              'এজন ধৈৰ্য্যশীল, মৰমীয়াল সংগী যিয়ে আপোনাৰ কথা মনোযোগেৰে শুনে, মধুৰ স্মৃতি সংৰক্ষণ কৰে আৰু আপোনজনক কাষত ৰাখে।',
          tags: ['কণ্ঠ-আধাৰিত', 'অমূল্য স্মৃতি', '১০০% সুৰক্ষিত'],
        ),
        OnboardingSlideTranslation(
          label: 'কণ্ঠ প্ৰথম',
          title: 'কেৱল কওক।\nসাথীয়ে শুনি আছে।',
          motto: 'আপোনাৰ নিজৰ ভাষাত সহজভাৱে কওক',
          description:
              'ডাঙৰ মাইক বুটামটো টিপক আৰু মুক্তভাৱে কওক। সাথীয়ে কোনো খৰখেদা নকৰাকৈ ধৈৰ্য্য আৰু মৰমেৰে শুনিব।',
          tags: ['আপোনাৰ ভাষা বুজে', 'শান্ত আৰু ধৈৰ্য্যশীল', 'সহজ ব্যৱহাৰ'],
        ),
        OnboardingSlideTranslation(
          label: 'মৰমৰ স্মৃতি',
          title: 'স্মৃতিবোৰ সুৰক্ষিত আৰু\nকাষত ৰাখক',
          motto: 'পৰিয়ালৰ আনন্দ আৰু হাঁহিৰ সংৰক্ষণ',
          description:
              'পৰিয়ালৰ ফটো, মাতৰ সাধু, চিনাকি মুখ আৰু বিশেষ দিনবোৰ এক শান্ত আৰু সুৰক্ষিত স্থানত সংৰক্ষণ কৰক।',
          tags: ['আপোন মুখ', 'কণ্ঠৰ সাধু', 'বিশেষ দিন'],
        ),
        OnboardingSlideTranslation(
          label: 'সদায় কাষত',
          title: 'সদায় আপোনাৰ লগত,\nঅফলাইনতো',
          motto: 'ইণ্টাৰনেট অবিহনে যিকোনো সময়তে কাষত',
          description:
              'মুখ্য সুবিধাসমূহ ইণ্টাৰনেট নোহোৱাকৈও চলে। আপোনাৰ ব্যক্তিগত স্মৃতিসমূহ সম্পূৰ্ণ গোপন আৰু সুৰক্ষিত থাকে।',
          tags: ['অফলাইন কাম কৰে', 'সম্পূৰ্ণ গোপনীয়তা', 'যত্নকৰ্তাৰ সৈতে সংযোগ'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'ঘৰ',
        voiceSaathi: 'কণ্ঠ সাথী',
        memories: 'স্মৃতি',
        activities: 'কাৰ্যসূচী',
        family: 'পৰিয়াল',
        askSaathi: 'সাথীক সোধক',
      ),
      home: HomeTranslation(
        greetingMorning: 'সুপ্ৰভাত',
        greetingAfternoon: 'শুভ দুপৰীয়া',
        greetingEvening: 'শুভ গধূলি',
        saathiReady: 'স্মৃতি সাথী প্ৰস্তুত',
        feelingQuestion: 'এতিয়া আপোনাৰ মনটো কেনে লাগিছে?',
        happy: 'আনন্দিত',
        peaceful: 'শান্ত',
        thoughtful: 'চিন্তাশীল',
        resting: 'জিৰণি',
        talkHeroTitle: 'কেৱল কওক। সাথীয়ে শুনিছে।',
        talkHeroSubtitle: 'সাধু কওক, সহায় বিচাৰক বা কেৱল নমস্কাৰ জনাওক।',
        tapToSpeak: 'কবলৈ স্পৰ্শ কৰক',
      ),
    ),

    'মৈতৈলোন্': AppTranslationData(
      languageName: 'মৈতৈলোন্',
      modalTitle: 'নখোইগী লোন খনবীয়ু',
      modalSubtitle: 'স্মৃতি সাথীনা নখোইগী মমা লোনদা নুংশিবগা লোয়ননা পাউ ফাওনগনি।',
      editionBadge: 'নোংপোক-অৱাং ভারত অমসুং লৈবাক্কী ইডিসন',
      confirmButton: 'চেক তৌদুনা মাংলোইদা চংশিল্লু',
      skipButton: 'থাদ্দোকউ',
      backButton: 'হন্দোকউ',
      continueButton: 'মাংলোইদা চংশিল্লু',
      getStartedButton: 'হৌদোকউ',
      mottoBanner: 'মরমদি নীংশিংপোৎ খুদিংমক লন অমনি...',
      footerTrust: 'শীজিন্নবদা লাইবা  •  নুংশিবগা লোয়ননা শাবা  •  ১০০% লোয়ননা লৈবা',
      slides: [
        OnboardingSlideTranslation(
          label: 'নখোইগী AI মরূপ',
          title: 'স্মৃতি সাথী',
          motto: 'নুমিৎ খুদিংগী পুন্সী অমসুং নীংশিংপোৎকীদমক AI মরূপ',
          description:
              'খমথেংনা তাবা, নুংশিবা মরূপ অমনি মসিনা নখোইগী নীংশিংপোৎশিংবু কনদুনা থম্বগা লোয়ননা নখোইগী নক্নবা মীওইশিংগা শম্নহন্দুনা থম্মি।',
          tags: ['খোঞ্জেল-অহানবা', 'লুবা নীংশিংপোৎ', '১০০% অরোইবা'],
        ),
        OnboardingSlideTranslation(
          label: 'খোঞ্জেল অহানবা',
          title: 'ৱা ঙাংবীয়ু হেক্তা।\nসাথীনা তারি।',
          motto: 'নখোইগী লোন্দা নিংতম্বা মওংদা ঙাংবীয়ু',
          description:
              'অচৌবা মাইক বুটন অসিবু নম্লগা ৱা ঙাংবীয়ু। সাথীনা খরা থুনা পাইশিনদনা তপ্না নুংশিনা তারি।',
          tags: ['নখোইগী লোন খঙই', 'তপ্না লৈবা', 'লাইনা শীজিন্নবা'],
        ),
        OnboardingSlideTranslation(
          label: 'নুংশিবা নীংশিংপোৎ',
          title: 'নীংশিংপোৎশিংবু চেকশিন্না\nনক্ননা থম্বীয়ু',
          motto: 'ইমুং মনুংগী হরাওবা অমসুং নোক্তুম্বাবু কনবা',
          description:
              'ইমুংগী ফোতোশিং, খোঞ্জেলগী ৱারীশিং অমসুং অখন্নবা নুমিৎশিংবু শান্তি লৈবা মফম অমদা চেকশিন্না থম্বীয়ু।',
          tags: ['ইমুংগী শক্তম', 'খোঞ্জেলগী ৱারী', 'অখন্নবা নুমিৎ'],
        ),
        OnboardingSlideTranslation(
          label: 'মতම් পুম্নমক্তা',
          title: 'মতම් পুম্বদা নখোইগা লোয়ননা,\nওফলাইনদসু',
          motto: 'ইন্তর্নেত য়াওদনা মতম পুম্বদা ফংবা',
          description:
              'মরুওইবা ফীচরশিং ইন্তর্নেত য়াওদনা শীজিন্নবা য়াই। নখোইগী নীংশিংপোৎশিং ১০০% চেকশিন্না লৈ।',
          tags: ['ওফলাইন থবক তৌবা', 'অরোইবা চেকশিনবা', 'য়েন্থোকপাগা শম্নবা'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'য়ুম',
        voiceSaathi: 'খোঞ্জেল সাথী',
        memories: 'নীংশিংপোৎ',
        activities: 'থবকশিং',
        family: 'ইমুং',
        askSaathi: 'সাথীদা হংবীয়ু',
      ),
      home: HomeTranslation(
        greetingMorning: 'নুমিৎসারকপগী য়াইফ-পাউজেল',
        greetingAfternoon: 'নুংথিলগী য়াইফ-পাউজেল',
        greetingEvening: 'নুমিদাংগী য়াইফ-পাউজেল',
        saathiReady: 'স্মৃতি সাথী শেম-শাদুনা লৈরে',
        feelingQuestion: 'হৌজিক অদোমগী ৱাখলদা করি ফাওই?',
        happy: 'হরাওবা',
        peaceful: 'শান্তি',
        thoughtful: 'ৱাখল খনব',
        resting: 'পোথাবা',
        talkHeroTitle: 'ৱা ঙাংবীয়ু হেক্তা। সাথীনা তারি।',
        talkHeroSubtitle: 'ৱারী অমতা শম্বীয়ু, মতেং নীবীয়ু নত্রগা খুরুমজরি হায়বীয়ু।',
        tapToSpeak: 'ঙাংনবগীদমক নম্বীয়ু',
      ),
    ),

    'Mizo': AppTranslationData(
      languageName: 'Mizo',
      modalTitle: 'I ṭawng duh thlang rawh',
      modalSubtitle: 'Smriti Saathi hian duat tak leh ngaihsak takin i ṭawng ngeiin a be zel ang che.',
      editionBadge: 'Hmar-Chhak India leh Ram Pum Huap Edition',
      confirmButton: 'Pawm la kal chhunzawm rawh',
      skipButton: 'Kal pelh',
      backButton: 'Kir leh',
      continueButton: 'Chhunzawm rawh',
      getStartedButton: 'Ṭan rawh le',
      mottoBanner: 'Hriatrengna tinte hi an hlu lutuk si a...',
      footerTrust: 'Hman a awlsam  •  Duat taka siam  •  100% Him leh Thup',
      slides: [
        OnboardingSlideTranslation(
          label: 'I AI ṬHIANTIPA',
          title: 'Smriti Saathi',
          motto: 'I nitin nun leh hriatrengna hlu tana i AI Saathi',
          description:
              'Ṭhian dawhthei leh hmangaihna ngah tak, i thil sawi ngun taka ngaithla a, i hriatrengna hlu vawnghimtu.',
          tags: ['Aw hman hmasak', 'Hriatrengna hlu', '100% Thuruk'],
        ),
        OnboardingSlideTranslation(
          label: 'AW HMAN HMASAK',
          title: 'Sawi tawp rawh.\nSaathi-in a ngaithla e.',
          motto: 'I tlangnelna ṭawng ngeiin sawi rawh',
          description:
              'Mic lem lian tak hi hmet la, zalen takin sawi rawh. Saathi hian hmanhmawh miah lovin dawhthei takin a ngaithla reng ang che.',
          tags: ['I ṭawng a hrethiam', 'A damin a dawhthei', 'Awlsam taka hman theih'],
        ),
        OnboardingSlideTranslation(
          label: 'HRIATRENGNA HLU',
          title: 'Hriatrengnate him tak leh\nhnaihah vawng rawh',
          motto: 'Chhungkaw sulhnu leh hlimna vawnhimna',
          description:
              'Chhungkaw thlalak, aw rawng kai thawnthu, hmel hriatte leh ni pawimawhte hmun ralmuang leh nuam takah vawngṭha rawh.',
          tags: ['Chhungkaw hmel', 'Aw thawnthu', 'Ni pawimawh'],
        ),
        OnboardingSlideTranslation(
          label: 'A AWM RENG',
          title: 'I kiangah a awm reng,\nOffline-ah pawh',
          motto: 'Engtik lai pawhin internet tello pawn a tlak tawk',
          description:
              'A thil pawimawh zawng zawng hi internet awm loh pawn a hman theih vek. I hriatrengnate a him em em a ni.',
          tags: ['Offline-ah a thawk', 'Hualhim 100%', 'Enkawltu nen inzawm'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'In',
        voiceSaathi: 'Aw Saathi',
        memories: 'Hriatrengna',
        activities: 'Thiltih',
        family: 'Chhungkua',
        askSaathi: 'Saathi zawt rawh',
      ),
      home: HomeTranslation(
        greetingMorning: 'Zing chibai',
        greetingAfternoon: 'Chhun chibai',
        greetingEvening: 'Tlai chibai',
        saathiReady: 'Smriti Saathi a inpeih reng e',
        feelingQuestion: 'Vawiin chu eng nge i an le?',
        happy: 'Hlim',
        peaceful: 'Thlamuang',
        thoughtful: 'Inngaihtuah',
        resting: 'Chawlhhahdam',
        talkHeroTitle: 'Sawi tawp rawh. Saathi-in a ngaithla e.',
        talkHeroSubtitle: 'Thawnthu sawi la, zawhna zawt rawh le.',
        tapToSpeak: 'Ṭawng turin hmet rawh',
      ),
    ),

    'नेपाली': AppTranslationData(
      languageName: 'नेपाली',
      modalTitle: 'आफ्नो भाषा छान्नुहोस्',
      modalSubtitle: 'स्मृति साथीले तपाईंको रोजाइको भाषामा स्नेह र मायाका साथ साथ दिनेछ।',
      editionBadge: 'पूर्वोत्तर भारत र राष्ट्रिय संस्करण',
      confirmButton: 'निश्चित गरी अगाडि बढ्नुहोस्',
      skipButton: 'छोड्नुहोस्',
      backButton: 'पछाडि',
      continueButton: 'अगाडि बढ्नुहोस्',
      getStartedButton: 'सुरु गर्नुहोस्',
      mottoBanner: 'किनकि हरेक सम्झना अनमोल छ...',
      footerTrust: 'प्रयोग गर्न सजिलो  •  मायाले बनाइएको  •  १००% सुरक्षित र व्यक्तिगत',
      slides: [
        OnboardingSlideTranslation(
          label: 'तपाईंको AI साथी',
          title: 'स्मृति साथी',
          motto: 'दैनिक जीवन र सम्झनाहरूका लागि तपाईंको AI साथी',
          description:
              'एक धैर्यवान्, मायालु साथी जसले तपाईंको कुरा ध्यान दिएर सुन्छ, मीठा सम्झनाहरू जोगाउँछ र आफन्तहरूसँग नजिक राख्छ।',
          tags: ['आवाज-आधारित', 'अनमोल सम्झना', '१००% सुरक्षित'],
        ),
        OnboardingSlideTranslation(
          label: 'आवाज पहिले',
          title: 'बोल्नुहोस् मात्र।\nसाथीले सुन्नेछ।',
          motto: 'आफ्नो सहज भाषामा खुलेर बोल्नुहोस्',
          description:
              'ठूलो माइक बटन थिच्नुहोस् र मन खोलेर बोल्नुहोस्। साथीले कुनै हतार नगरी धैर्य र मायाका साथ सुन्नेछ।',
          tags: ['तपाईंको भाषा बुझ्छ', 'शान्त र धैर्यवान्', 'सजिलो उपयोग'],
        ),
        OnboardingSlideTranslation(
          label: 'प्यारा सम्झनाहरू',
          title: 'सम्झनाहरू सुरक्षित र\nनजिक राख्नुहोस्',
          motto: 'पारिवारिक खुसी र मुस्कानको संरक्षण',
          description:
              'पारिवारिक फोटोहरू, आवाजका कथाहरू, परिचित अनुहारहरू र विशेष मितिहरू एक शान्त र सुरक्षित ठाउँमा सुरक्षित राख्नुहोस्।',
          tags: ['आफन्तका अनुहार', 'आवाजका कथा', 'विशेष मिति'],
        ),
        OnboardingSlideTranslation(
          label: 'सधैं उपलब्ध',
          title: 'सधैं तपाईंसँग,\nअफलाइन पनि',
          motto: 'इन्टरनेट बिना जुनसुकै बेला, जताततै उपलब्ध',
          description:
              'मुख्य सुविधाहरू इन्टरनेट बिना पनि पूर्ण रूपमा काम गर्दछन्। तपाईंका व्यक्तिगत सम्झनाहरू पूर्ण सुरक्षित रहन्छन्।',
          tags: ['अफलाइन काम गर्छ', 'पूर्ण गोपनीयता', 'हेरचाहकर्तासँग जोडिएको'],
        ),
      ],
      auth: AuthScreenTranslation.defaultAuth,
      nav: ShellTranslation(
        home: 'गृह',
        voiceSaathi: 'आवाज साथी',
        memories: 'सम्झनाहरू',
        activities: 'क्रियाकलाप',
        family: 'परिवार',
        askSaathi: 'साथीलाई सोध्नुहोस्',
      ),
      home: HomeTranslation(
        greetingMorning: 'शुभ प्रभात',
        greetingAfternoon: 'शुभ दिउँसो',
        greetingEvening: 'शुभ सन्ध्या',
        saathiReady: 'स्मृति साथी तयार छ',
        feelingQuestion: 'अहिले तपाईंलाई कस्तो महसुस भइरहेको छ?',
        happy: 'खुसी',
        peaceful: 'शान्त',
        thoughtful: 'विचारशील',
        resting: 'आराम',
        talkHeroTitle: 'बोल्नुहोस् मात्र। साथीले सुन्दैछ।',
        talkHeroSubtitle: 'कुराकानी गर्नुहोस्, सोध्नुहोस् वा नमस्ते भन्नुहोस्।',
        tapToSpeak: 'बोल्नका लागि छुनुहोस्',
      ),
    ),
  };

  static AppTranslationData get(String language) {
    if (_data.containsKey(language)) {
      return _data[language]!;
    }
    for (final entry in _data.entries) {
      if (entry.key.toLowerCase() == language.toLowerCase() ||
          entry.value.languageName.toLowerCase() == language.toLowerCase()) {
        return entry.value;
      }
    }
    final l = language.toLowerCase();
    if (l.contains('tamil') || l.contains('தமிழ்')) return _data['தமிழ்']!;
    if (l.contains('telugu') || l.contains('తెలుగు')) return _data['తెలుగు']!;
    if (l.contains('kannada') || l.contains('ಕನ್ನಡ')) return _data['ಕನ್ನಡ']!;
    if (l.contains('malayalam') || l.contains('മലയാളം')) return _data['മലയാളം']!;
    if (l.contains('marathi') || l.contains('मराठी')) return _data['मराठी']!;
    if (l.contains('gujarati') || l.contains('ગુજરાતી')) return _data['ગુજરાતી']!;
    if (l.contains('punjabi') || l.contains('ਪੰਜਾਬੀ')) return _data['ਪੰਜਾਬੀ']!;
    if (l.contains('odia') || l.contains('oriya') || l.contains('ଓଡ଼ିଆ')) return _data['ଓଡ଼ିଆ']!;
    if (l.contains('assam') || l.contains('অসমীয়া')) return _data['অসমীয়া']!;
    if (l.contains('bengal') || l.contains('বাংলা')) return _data['বাংলা']!;
    if (l.contains('manipuri') || l.contains('meitei') || l.contains('মৈতৈ')) return _data['মৈতৈলোন্']!;
    if (l.contains('mizo')) return _data['Mizo']!;
    if (l.contains('nepal') || l.contains('नेपाली')) return _data['नेपाली']!;
    if (l.contains('hindi') || l.contains('हिंदी') || l.contains('हिन्दी')) return _data['हिन्दी']!;
    return _data['English']!;
  }

  static AuthScreenTranslation getAuth(String language) {
    return get(language).auth;
  }

  static ShellTranslation getNav(String language) {
    return get(language).nav;
  }

  static HomeTranslation getHome(String language) {
    return get(language).home;
  }
}
