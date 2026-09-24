import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/memory_service.dart';
import '../services/saathi_ai_engine.dart';
import '../services/speech_service.dart';
import '../services/voice_engine.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/fx/fade_slide_in.dart';
import '../widgets/offline_badge.dart';

/// Memories gallery — category tabs (People / Places / Objects / Moments),
/// a large featured card and a two-column grid, each memory showing its photo,
/// a spoken "listen" control, and a favorite heart. Fully offline: photos are
/// picked from the device gallery and read from local files.
class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen>
    with SingleTickerProviderStateMixin {
  final MemoryService _memoryService = MemoryService();
  final SpeechService _speech = SpeechService();

  String _selectedCategory = kMemoryCategories.first; // People
  MemoryItem? _activeQuizMemory;

  // Which memory is currently being narrated, plus its progress animation.
  String? _playingId;
  late final AnimationController _playbackCtrl;

  @override
  void initState() {
    super.initState();
    _playbackCtrl = AnimationController(vsync: this);
    _memoryService.addListener(_onMemoriesChanged);
    // Land on the first tab that actually has memories.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickInitialTab());
  }

  void _pickInitialTab() {
    for (final cat in kMemoryCategories) {
      if (_memoryService.byCategory(cat).isNotEmpty) {
        if (mounted) setState(() => _selectedCategory = cat);
        return;
      }
    }
  }

  void _onMemoriesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _memoryService.removeListener(_onMemoriesChanged);
    _playbackCtrl.dispose();
    VoiceEngine().stop();
    super.dispose();
  }

  // ── Spoken playback ────────────────────────────────────────────
  Future<void> _togglePlay(MemoryItem memory) async {
    if (_playingId == memory.id) {
      await VoiceEngine().stop();
      _stopPlayback();
      return;
    }
    final settings = AppSettingsScope.of(context);
    await VoiceEngine().stop();
    final text = memory.reminiscenceStory.isNotEmpty
        ? memory.reminiscenceStory
        : (memory.description.isNotEmpty ? memory.description : memory.title);

    // Estimate spoken duration (~14 chars/sec) to drive the progress bar.
    final seconds = (text.length / 14).clamp(2, 60).toDouble();
    setState(() => _playingId = memory.id);
    _playbackCtrl
      ..duration = Duration(milliseconds: (seconds * 1000).round())
      ..forward(from: 0);

    await VoiceEngine().speak(
      text,
      language: settings.language,
      rate: settings.voiceRate,
      pitch: settings.voicePitch,
      onDone: _stopPlayback,
    );
  }

  void _stopPlayback() {
    if (!mounted) return;
    _playbackCtrl.stop();
    setState(() => _playingId = null);
  }

  Future<void> _toggleFavorite(MemoryItem memory) async {
    await _memoryService.toggleFavorite(memory.id);
  }

  void _startMemoryVoiceRecall(MemoryItem memory) {
    setState(() => _activeQuizMemory = memory);
    SaathiAiEngine.setActiveRecallMemory(memory);
    VoiceEngine().stop();
    _stopPlayback();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemoryRecallModal(
        memory: _activeQuizMemory ?? memory,
        speech: _speech,
        memoryService: _memoryService,
      ),
    );
  }
  // ── Add memory (with gallery photo) ────────────────────────────
  void _showAddMemoryDialog() {
    final titleCtrl = TextEditingController();
    final eventCtrl = TextEditingController();
    final personsCtrl = TextEditingController();
    final questionCtrl = TextEditingController();
    final answerCtrl = TextEditingController();
    final storyCtrl = TextEditingController();
    String cat = _selectedCategory;
    String? pickedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pick(bool camera) async {
              final path = await _memoryService.pickImage(fromCamera: camera);
              if (path != null) setModalState(() => pickedImagePath = path);
            }

            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 48, height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Add a Memory',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.deepForest)),
                    const SizedBox(height: 4),
                    const Text('Pick a photo from the gallery and add a story Saathi can narrate.',
                        style: TextStyle(fontSize: 13, color: AppTheme.muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    _AddImagePicker(
                      imagePath: pickedImagePath,
                      onGallery: () => pick(false),
                      onCamera: () => pick(true),
                      onClear: () => setModalState(() => pickedImagePath = null),
                    ),
                    const SizedBox(height: 14),
                    _CategoryChooser(
                      selected: cat,
                      onSelect: (c) => setModalState(() => cat = c),
                    ),
                    const SizedBox(height: 12),
                    _sheetField(titleCtrl, 'Memory Title', 'e.g. My Family'),
                    const SizedBox(height: 10),
                    _sheetField(eventCtrl, 'Event / Occasion', 'e.g. Diwali 2024'),
                    const SizedBox(height: 10),
                    _sheetField(personsCtrl, 'Tagged People', 'e.g. Meena, Arun'),
                    const SizedBox(height: 10),
                    _sheetField(questionCtrl, 'Recall Question', 'e.g. Who is beside you here?'),
                    const SizedBox(height: 10),
                    _sheetField(answerCtrl, 'Answer / Person', 'e.g. Daughter Meena'),
                    const SizedBox(height: 10),
                    _sheetField(storyCtrl, 'Story Saathi Narrates', 'Describe this happy moment…', maxLines: 3),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius18)),
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final persons = personsCtrl.text
                            .split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
                        await _memoryService.addMemory(
                          title: titleCtrl.text.trim(),
                          subtitle: eventCtrl.text.trim().isNotEmpty ? eventCtrl.text.trim() : cat,
                          category: cat,
                          event: eventCtrl.text.trim(),
                          taggedPersons: persons,
                          description: storyCtrl.text.trim().isNotEmpty ? storyCtrl.text.trim() : titleCtrl.text.trim(),
                          recallQuestion: questionCtrl.text.trim().isNotEmpty
                              ? questionCtrl.text.trim()
                              : 'Do you remember this moment?',
                          recallAnswer: answerCtrl.text.trim().isNotEmpty
                              ? answerCtrl.text.trim()
                              : (persons.isNotEmpty ? persons.first : ''),
                          alternativeAnswers: persons,
                          reminiscenceStory: storyCtrl.text.trim().isNotEmpty
                              ? storyCtrl.text.trim()
                              : 'A lovely memory cherished forever.',
                          mediaPath: pickedImagePath,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          setState(() => _selectedCategory = cat);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Memory saved — available offline.')));
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Save Memory', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetField(TextEditingController c, String label, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppTheme.cream,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius16)),
      ),
    );
  }
  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final items = _memoryService.byCategory(_selectedCategory);
    final featured = items.isNotEmpty ? items.first : null;
    final rest = items.length > 1 ? items.sublist(1) : <MemoryItem>[];

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Memories',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OfflineBadge(compact: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemoryDialog,
        backgroundColor: AppTheme.forest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTabs(),
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                      children: [
                        if (featured != null)
                          FadeSlideIn(child: _buildFeaturedCard(featured)),
                        const SizedBox(height: 14),
                        if (rest.isNotEmpty)
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.82,
                            children: [
                              for (final m in rest) _buildGridCard(m),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: kMemoryCategories.map((cat) {
          final selected = _selectedCategory == cat;
          final count = _memoryService.byCategory(cat).length;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedScaleButton(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.forest : AppTheme.paper,
                  borderRadius: BorderRadius.circular(AppTheme.radius18),
                  border: Border.all(color: selected ? AppTheme.forest : AppTheme.divider),
                  boxShadow: selected ? AppTheme.softShadow : const [],
                ),
                child: Text(
                  count > 0 ? '$cat ($count)' : cat,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    color: selected ? Colors.white : AppTheme.deepForest,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  // ── Cards ──────────────────────────────────────────────────────
  Widget _buildFeaturedCard(MemoryItem m) {
    final playing = _playingId == m.id;
    return AnimatedScaleButton(
      onTap: () => _openStoryModal(m),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(AppTheme.radius24),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.divider, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _memoryImage(m, height: 190),
                Positioned(
                  top: 10, right: 10,
                  child: _heartButton(m),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppTheme.deepForest)),
                  const SizedBox(height: 3),
                  Text(m.subtitle.isNotEmpty ? m.subtitle : m.category,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.muted)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _playButton(m, large: true),
                      const SizedBox(width: 12),
                      Expanded(child: _progressBar(playing)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(MemoryItem m) {
    return AnimatedScaleButton(
      onTap: () => _openStoryModal(m),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(AppTheme.radius24),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.divider, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _memoryImage(m)),
                  Positioned(top: 6, right: 6, child: _heartButton(m, small: true)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.deepForest)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(m.subtitle.isNotEmpty ? m.subtitle : m.category,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.muted)),
                      ),
                      _playButton(m),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playButton(MemoryItem m, {bool large = false}) {
    final playing = _playingId == m.id;
    final size = large ? 44.0 : 34.0;
    return GestureDetector(
      onTap: () => _togglePlay(m),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: playing ? AppTheme.warmAmber : AppTheme.forest,
          shape: BoxShape.circle,
          boxShadow: AppTheme.softShadow,
        ),
        child: Icon(
          playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: Colors.white, size: large ? 26 : 20),
      ),
    );
  }

  Widget _heartButton(MemoryItem m, {bool small = false}) {
    return GestureDetector(
      onTap: () => _toggleFavorite(m),
      child: Container(
        padding: EdgeInsets.all(small ? 5 : 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: AppTheme.softShadow,
        ),
        child: Icon(
          m.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: m.favorite ? AppTheme.terracotta : AppTheme.muted,
          size: small ? 16 : 20,
        ),
      ),
    );
  }

  Widget _progressBar(bool playing) {
    return AnimatedBuilder(
      animation: _playbackCtrl,
      builder: (context, _) {
        final value = playing ? _playbackCtrl.value : 0.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: playing ? value : 0,
            minHeight: 7,
            backgroundColor: AppTheme.divider,
            valueColor: const AlwaysStoppedAnimation(AppTheme.forest),
          ),
        );
      },
    );
  }

  Widget _memoryImage(MemoryItem m, {double? height}) {
    Widget placeholder() => Container(
          height: height,
          color: m.color,
          alignment: Alignment.center,
          child: Icon(m.icon, size: 40, color: AppTheme.forest),
        );

    final path = m.mediaPath;
    if (path == null || path.isEmpty) return placeholder();

    Widget img;
    if (m.hasLocalImage) {
      img = Image.file(File(path),
          height: height, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder());
    } else if (path.startsWith('http')) {
      img = Image.network(path,
          height: height, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder());
    } else {
      img = Image.asset(path,
          height: height, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder());
    }
    return img;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.sage.withValues(alpha: 0.5),
                shape: BoxShape.circle),
              child: const Icon(Icons.auto_stories_rounded, size: 46, color: AppTheme.forest),
            ),
            const SizedBox(height: 16),
            Text('No $_selectedCategory memories yet',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.deepForest)),
            const SizedBox(height: 6),
            const Text('Tap “Add” to pick a photo from the gallery and save a memory.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }

  // ── Story modal (view + listen + quiz) ─────────────────────────
  void _openStoryModal(MemoryItem memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50, height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.divider, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              if (memory.mediaPath != null && memory.mediaPath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius18),
                  child: _memoryImage(memory, height: 180),
                ),
              const SizedBox(height: 14),
              Text(memory.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.deepForest)),
              const SizedBox(height: 6),
              Text(
                memory.reminiscenceStory.isNotEmpty ? memory.reminiscenceStory : memory.description,
                style: const TextStyle(fontSize: 16, height: 1.5, color: AppTheme.deepForest, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warmAmber,
                        foregroundColor: AppTheme.deepForest,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius18)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _startMemoryVoiceRecall(memory);
                      },
                      icon: const Icon(Icons.psychology_rounded, size: 20),
                      label: const Text('Memory Quiz', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius18)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _togglePlay(memory);
                    },
                    icon: const Icon(Icons.volume_up_rounded, size: 20),
                    label: const Text('Listen'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Add-memory sub-widgets ─────────────────────────────────────────
class _AddImagePicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onClear;
  const _AddImagePicker({
    required this.imagePath,
    required this.onGallery,
    required this.onCamera,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius18),
            child: kIsWeb
                ? Image.network(imagePath!, height: 160, width: double.infinity, fit: BoxFit.cover)
                : Image.file(File(imagePath!), height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: _pickBtn(Icons.photo_library_rounded, 'Gallery', onGallery)),
        const SizedBox(width: 10),
        Expanded(child: _pickBtn(Icons.photo_camera_rounded, 'Camera', onCamera)),
      ],
    );
  }

  Widget _pickBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(AppTheme.radius18),
          border: Border.all(color: AppTheme.divider, width: 1.4),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.forest, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.deepForest)),
          ],
        ),
      ),
    );
  }
}

class _CategoryChooser extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _CategoryChooser({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: kMemoryCategories.map((c) {
        final sel = c == selected;
        return ChoiceChip(
          label: Text(c),
          selected: sel,
          onSelected: (_) => onSelect(c),
          selectedColor: AppTheme.forest,
          backgroundColor: AppTheme.cream,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w800,
            color: sel ? Colors.white : AppTheme.deepForest),
        );
      }).toList(),
    );
  }
}

class _MemoryRecallModal extends StatefulWidget {
  final MemoryItem memory;
  final SpeechService speech;
  final MemoryService memoryService;

  const _MemoryRecallModal({
    required this.memory,
    required this.speech,
    required this.memoryService,
  });

  @override
  State<_MemoryRecallModal> createState() => _MemoryRecallModalState();
}

class _MemoryRecallModalState extends State<_MemoryRecallModal> {
  bool _isListening = false;
  String _userAnswer = '';
  String? _feedback;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakQuestion();
    });
  }

  @override
  void dispose() {
    VoiceEngine().stop();
    widget.speech.stopListening();
    super.dispose();
  }

  void _speakQuestion() async {
    final settings = AppSettingsScope.of(context);
    final text = "Amma, look at this memory of ${widget.memory.title}. ${widget.memory.recallQuestion}";
    await VoiceEngine().speak(
      text,
      language: settings.language,
      rate: settings.voiceRate,
      pitch: settings.voicePitch,
    );
  }

  void _toggleListening() async {
    final settings = AppSettingsScope.of(context);
    if (_isListening) {
      await widget.speech.stopListening();
      if (!mounted) return;
      setState(() => _isListening = false);
      if (_userAnswer.isNotEmpty) {
        _evaluateAnswer(_userAnswer);
      }
      return;
    }

    await VoiceEngine().stop();
    if (!mounted) return;
    setState(() {
      _isListening = true;
      _userAnswer = '';
      _feedback = null;
    });

    await widget.speech.startListening(
      language: settings.language,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _userAnswer = text);
        if (isFinal && text.trim().isNotEmpty) {
          _evaluateAnswer(text);
        }
      },
    );
  }

  void _evaluateAnswer(String answer) async {
    final settings = AppSettingsScope.of(context);
    await widget.speech.stopListening();
    final correct = widget.memoryService.evaluateAnswer(widget.memory, answer);

    String fb = '';
    if (correct) {
      fb = 'Wonderful memory, Amma! Exactly right: ${widget.memory.recallAnswer}. ${widget.memory.reminiscenceStory}';
    } else {
      fb = 'Good try! For this memory, the answer is ${widget.memory.recallAnswer}. ${widget.memory.reminiscenceStory}';
    }

    if (!mounted) return;
    setState(() {
      _isListening = false;
      _isCorrect = correct;
      _feedback = fb;
    });

    await VoiceEngine().speak(
      fb,
      language: settings.language,
      rate: settings.voiceRate,
      pitch: settings.voicePitch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: widget.memory.color, shape: BoxShape.circle),
                  child: Icon(widget.memory.icon, color: AppTheme.forest, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.memory.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.deepForest),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.warmAmber.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Memory Question from Saathi:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.forest),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.memory.recallQuestion,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.deepForest, height: 1.3),
                  ),
                ],
              ),
            ),
            if (_userAnswer.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.sage, borderRadius: BorderRadius.circular(12)),
                child: Text('Your voice answer: "$_userAnswer"', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.forest)),
              ),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isCorrect == true ? AppTheme.sage : AppTheme.softGold,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _feedback!,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _isCorrect == true ? AppTheme.deepForest : AppTheme.deepForest,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isListening ? AppTheme.goldGradient : AppTheme.emeraldGradient,
                    boxShadow: _isListening ? AppTheme.amberGlow : AppTheme.emeraldGlow,
                  ),
                  child: Icon(
                    _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _isListening ? 'Listening… Speak answer now' : 'Tap to speak your answer',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
