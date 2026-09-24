import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/memory_service.dart';
import '../services/voice_engine.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/screen_header.dart';

/// The Photo Memory companion loop (§ photo memory companion): the user shares
/// a photo, Saathi asks a few gentle questions one at a time, and the answers
/// become a structured [MemoryItem] that also grows the memory graph — no AI
/// vision, just a warm conversation about the picture.
class PhotoMemoryScreen extends StatefulWidget {
  const PhotoMemoryScreen({super.key});

  @override
  State<PhotoMemoryScreen> createState() => _PhotoMemoryScreenState();
}

/// One gentle question Saathi asks about the photo.
class _Q {
  final String key;
  final String prompt;
  final String hint;
  const _Q(this.key, this.prompt, this.hint);
}

const _questions = <_Q>[
  _Q('who', 'Who is in this photo?',
      'e.g. My daughter Meera, and my grandson Aarav'),
  _Q('where', 'Where was this?', 'e.g. Our home in Jorhat, during Bihu'),
  _Q('what', 'What was happening here?',
      'e.g. We were celebrating together after the harvest'),
  _Q('feel', 'What do you love about this memory?',
      'e.g. Everyone was laughing and the food smelled wonderful'),
];

class _PhotoMemoryScreenState extends State<PhotoMemoryScreen> {
  final _memory = MemoryService();
  final _controller = TextEditingController();

  String? _photoPath;
  int _step = 0; // index into _questions
  final Map<String, String> _answers = {};
  bool _saving = false;
  bool _done = false;
  bool _bound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bind());
  }

  void _bind() {
    if (_bound) return;
    final auth = AuthScope.of(context);
    _memory.patientId = auth.activePatient?.id;
    _memory.selfName = auth.activePatient?.name ?? '';
    _bound = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool camera}) async {
    final path = await _memory.pickImage(fromCamera: camera);
    if (path == null || !mounted) return;
    setState(() {
      _photoPath = path;
      _step = 0;
    });
    _speakCurrent();
  }

  void _speakCurrent() {
    if (_step < _questions.length) {
      VoiceEngine().speak(_questions[_step].prompt);
    }
  }

  void _next() {
    _answers[_questions[_step].key] = _controller.text.trim();
    _controller.clear();
    if (_step + 1 >= _questions.length) {
      _save();
      return;
    }
    setState(() => _step++);
    _speakCurrent();
  }

  void _skip() {
    _answers[_questions[_step].key] = '';
    _controller.clear();
    if (_step + 1 >= _questions.length) {
      _save();
      return;
    }
    setState(() => _step++);
    _speakCurrent();
  }

  // Parse the free-text "who" answer into tagged persons. A phrase like
  // "my daughter Meera and my son Arun" → ["Meera (daughter)", "Arun (son)"].
  List<String> _parsePeople(String raw) {
    if (raw.trim().isEmpty) return const [];
    const rels = [
      'daughter', 'son', 'wife', 'husband', 'mother', 'father', 'sister',
      'brother', 'grandson', 'granddaughter', 'grandmother', 'grandfather',
      'friend', 'neighbour', 'neighbor', 'cousin', 'aunt', 'uncle', 'niece',
      'nephew',
    ];
    final people = <String>[];
    final parts = raw.split(RegExp(r',|\band\b', caseSensitive: false));
    for (final part in parts) {
      final seg = part.trim();
      if (seg.isEmpty) continue;
      String? rel;
      for (final r in rels) {
        if (seg.toLowerCase().contains(r)) {
          rel = r;
          break;
        }
      }
      // The name is the capitalised word(s) that aren't relationship/filler.
      final words = seg
          .replaceAll(RegExp(r'\b(my|our|the|a|an)\b', caseSensitive: false), '')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty && !rels.contains(w.toLowerCase()))
          .toList();
      final name = words.join(' ').trim();
      if (name.isEmpty) continue;
      people.add(rel != null ? '$name ($rel)' : name);
    }
    return people;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final who = _answers['who'] ?? '';
    final where = _answers['where'] ?? '';
    final what = _answers['what'] ?? '';
    final feel = _answers['feel'] ?? '';
    final people = _parsePeople(who);

    final title = where.isNotEmpty
        ? where
        : people.isNotEmpty
            ? 'With ${people.first.split('(').first.trim()}'
            : 'A special moment';
    final category = people.isNotEmpty
        ? 'People'
        : where.isNotEmpty
            ? 'Places'
            : 'Moments';
    final story = [what, feel].where((s) => s.isNotEmpty).join(' ');

    await _memory.addMemory(
      title: title,
      subtitle: where,
      category: category,
      event: where,
      taggedPersons: people,
      description: what,
      recallQuestion: who.isNotEmpty ? 'Who is in this photo?' : '',
      recallAnswer: people.isNotEmpty
          ? people.first.split('(').first.trim()
          : '',
      alternativeAnswers:
          people.map((p) => p.split('(').first.trim()).toList(),
      reminiscenceStory: story,
      mediaPath: _photoPath,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      _done = true;
    });
    VoiceEngine().speak('Thank you for sharing that with me. '
        'I will remember it for you.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Share a photo', showBack: true),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_saving) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_done) return _buildDone();
    if (_photoPath == null) return _buildPicker();
    return _buildQuestion();
  }

  Widget _buildPicker() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera_front_rounded,
                size: 72, color: AppTheme.sage),
            const SizedBox(height: 18),
            Text('Let\'s look at a photo together',
                textAlign: TextAlign.center,
                style: GoogleFonts.comfortaa(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepForest)),
            const SizedBox(height: 10),
            Text(
              'Choose a picture that means something to you, and I\'ll ask '
              'you a little about it.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: AppTheme.muted, height: 1.4),
            ),
            const SizedBox(height: 26),
            _bigButton('Choose from gallery', Icons.photo_library_rounded,
                () => _pick(camera: false)),
            const SizedBox(height: 12),
            _bigButton('Take a photo', Icons.camera_alt_rounded,
                () => _pick(camera: true),
                filled: false),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_step];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_questions.length, (i) {
            return Container(
              width: 26,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i <= _step ? AppTheme.forest : AppTheme.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        if (_photoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius28),
            child: Image(
              image: FileImage(File(_photoPath!)),
              height: 230,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          q.prompt,
          textAlign: TextAlign.center,
          style: GoogleFonts.comfortaa(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepForest,
              height: 1.3),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _controller,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.dmSans(fontSize: 18, color: AppTheme.ink),
          decoration: InputDecoration(
            hintText: q.hint,
            hintStyle: GoogleFonts.dmSans(
                fontSize: 15, color: AppTheme.muted, height: 1.3),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius18),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius18),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius18),
              borderSide: const BorderSide(color: AppTheme.forest, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _bigButton(
            _step + 1 >= _questions.length ? 'Save this memory' : 'Continue',
            Icons.arrow_forward_rounded,
            _next),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _skip,
            child: Text('Skip this one',
                style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.muted)),
          ),
        ),
      ],
    );
  }

  Widget _buildDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded,
                size: 64, color: AppTheme.coral),
            const SizedBox(height: 16),
            Text('I\'ll remember this for you',
                textAlign: TextAlign.center,
                style: GoogleFonts.comfortaa(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepForest)),
            const SizedBox(height: 10),
            Text(
              'This memory is now part of your Memory Garden. We can talk '
              'about it anytime.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 15, color: AppTheme.muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            _bigButton('Add another photo', Icons.add_rounded, () {
              setState(() {
                _photoPath = null;
                _answers.clear();
                _step = 0;
                _done = false;
              });
            }),
            const SizedBox(height: 12),
            _bigButton('Done', Icons.check_rounded,
                () => Navigator.of(context).maybePop(),
                filled: false),
          ],
        ),
      ),
    );
  }

  Widget _bigButton(String label, IconData icon, VoidCallback onTap,
      {bool filled = true}) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled ? AppTheme.emeraldGradient : null,
          color: filled ? null : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radius18),
          border:
              filled ? null : Border.all(color: AppTheme.divider, width: 1.6),
          boxShadow: filled ? AppTheme.buttonGlow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: filled ? Colors.white : AppTheme.forest, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: filled
                    ? AppTheme.buttonText(fontSize: 17)
                    : GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forest)),
          ],
        ),
      ),
    );
  }
}

