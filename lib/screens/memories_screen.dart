import 'package:flutter/material.dart';

import '../services/memory_service.dart';
import '../services/saathi_ai_engine.dart';
import '../services/speech_service.dart';
import '../services/voice_engine.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/offline_badge.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final MemoryService _memoryService = MemoryService();
  final SpeechService _speech = SpeechService();

  String _selectedCategory = 'All';
  final String _searchQuery = '';
  MemoryItem? _activeQuizMemory;
  bool _isSpeakingStory = false;

  final List<String> _categories = [
    'All',
    'Family',
    'Places',
    'Festivals',
    'Childhood',
  ];

  @override
  void initState() {
    super.initState();
    _memoryService.addListener(_onMemoriesChanged);
  }

  void _onMemoriesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _memoryService.removeListener(_onMemoriesChanged);
    VoiceEngine().stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    try {
      final settings = AppSettingsScope.of(context);
      setState(() => _isSpeakingStory = true);
      await VoiceEngine().speak(
        text,
        language: settings.language,
        rate: settings.voiceRate,
        pitch: settings.voicePitch,
        onDone: () {
          if (mounted) setState(() => _isSpeakingStory = false);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _isSpeakingStory = false);
    }
  }

  void _requestMediaPermission() async {
    final granted = await _memoryService.requestMediaPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Photo & Video album access granted! Saathi can now use memories for voice recall.'
                : 'Album permission enabled for memory recall.',
          ),
          backgroundColor: AppTheme.forest,
        ),
      );
    }
  }

  void _startMemoryVoiceRecall(MemoryItem memory) {
    setState(() => _activeQuizMemory = memory);
    SaathiAiEngine.setActiveRecallMemory(memory);

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
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: memory.color,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(memory.icon, size: 32, color: AppTheme.forest),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.paleTerracotta,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            memory.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.terracotta,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.deepForest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tagged Persons & Event
              if (memory.taggedPersons.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: memory.taggedPersons.map((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.sage,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_rounded, size: 14, color: AppTheme.forest),
                          const SizedBox(width: 4),
                          Text(
                            p,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.forest,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                memory.reminiscenceStory.isNotEmpty ? memory.reminiscenceStory : memory.description,
                style: const TextStyle(
                  fontSize: 16.5,
                  height: 1.5,
                  color: AppTheme.deepForest,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warmAmber,
                        foregroundColor: AppTheme.deepForest,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _startMemoryVoiceRecall(memory);
                      },
                      icon: const Icon(Icons.psychology_rounded, size: 20),
                      label: const Text('Try Memory Quiz', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius18),
                      ),
                    ),
                    onPressed: () => _speak(memory.reminiscenceStory),
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

  void _showAddMemoryDialog() {
    final titleCtrl = TextEditingController();
    final eventCtrl = TextEditingController();
    final personsCtrl = TextEditingController();
    final questionCtrl = TextEditingController();
    final answerCtrl = TextEditingController();
    final storyCtrl = TextEditingController();
    String cat = 'Family';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Add Memory with Photo & Recall Question',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Saathi uses these details to ask memory questions to the senior.',
                      style: TextStyle(fontSize: 13, color: AppTheme.muted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Memory Title',
                        hintText: 'e.g. Meena\'s Birthday Party',
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: eventCtrl,
                      decoration: InputDecoration(
                        labelText: 'Event / Occasion',
                        hintText: 'e.g. Birthday Celebration 2024',
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: personsCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tagged Family Members',
                        hintText: 'e.g. Daughter Meena, Granddaughter Lakshmi',
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: questionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Recall Question for Senior',
                        hintText: 'e.g. Who brought the chocolate cake for you?',
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: answerCtrl,
                      decoration: InputDecoration(
                        labelText: 'Correct Answer / Person',
                        hintText: 'e.g. Daughter Meena',
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: storyCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Story Saathi Narrates',
                        hintText: 'Describe the happy moment with love...',
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius16)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius18)),
                      ),
                      onPressed: () {
                        if (titleCtrl.text.trim().isNotEmpty) {
                          final persons = personsCtrl.text
                              .split(',')
                              .map((p) => p.trim())
                              .where((p) => p.isNotEmpty)
                              .toList();

                          _memoryService.addMemory(
                            title: titleCtrl.text.trim(),
                            subtitle: eventCtrl.text.trim().isNotEmpty
                                ? eventCtrl.text.trim()
                                : 'Family memory',
                            category: cat,
                            event: eventCtrl.text.trim(),
                            taggedPersons: persons,
                            description: storyCtrl.text.trim().isNotEmpty
                                ? storyCtrl.text.trim()
                                : titleCtrl.text.trim(),
                            recallQuestion: questionCtrl.text.trim().isNotEmpty
                                ? questionCtrl.text.trim()
                                : 'Do you remember who was with you during ${titleCtrl.text.trim()}?',
                            recallAnswer: answerCtrl.text.trim().isNotEmpty
                                ? answerCtrl.text.trim()
                                : (persons.isNotEmpty ? persons.first : 'Family'),
                            alternativeAnswers: persons,
                            reminiscenceStory: storyCtrl.text.trim().isNotEmpty
                                ? storyCtrl.text.trim()
                                : 'A lovely family memory cherished forever.',
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('New family memory & recall question saved!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Save Memory for Senior', style: TextStyle(fontWeight: FontWeight.w900)),
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

  @override
  Widget build(BuildContext context) {
    final allMems = _memoryService.memories;
    final filtered = allMems.where((m) {
      final matchesCat = _selectedCategory == 'All' || m.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.taggedPersons.any((p) => p.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Cherished Memories',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        actions: [
          if (_isSpeakingStory)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.volume_up_rounded, color: AppTheme.forest),
            ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: OfflineBadge(compact: true),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Media Permission & Photo Access Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.paper,
                    borderRadius: BorderRadius.circular(AppTheme.radius24),
                    boxShadow: AppTheme.softShadow,
                    border: Border.all(color: AppTheme.warmAmber.withValues(alpha: 0.5), width: 1.4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppTheme.softGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.perm_media_rounded, color: AppTheme.deepForest, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Photo & Video Memories',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.deepForest,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _memoryService.hasPhotoPermission
                                  ? 'Album access active • AI recall enabled'
                                  : 'Enable album access for photos & videos',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_memoryService.hasPhotoPermission)
                        ElevatedButton(
                          onPressed: _requestMediaPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.forest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Enable', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.sage,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.forest),
                              SizedBox(width: 4),
                              Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.forest)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Hero: Memory Quiz Banner & Recall Score
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radius24),
                    boxShadow: AppTheme.amberGlow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology_rounded, color: AppTheme.deepForest, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Voice Memory Challenge',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.deepForest,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Saathi asks questions about people & past events',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.deepForest,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final mem = _memoryService.getRandomRecallMemory();
                          if (mem != null) _startMemoryVoiceRecall(mem);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deepForest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Start Quiz', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Add Memory Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const Text(
                      'All Albums & Stories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    const Spacer(),
                    AnimatedScaleButton(
                      onTap: _showAddMemoryDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.sage,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 16, color: AppTheme.forest),
                            SizedBox(width: 6),
                            Text(
                              '+ Add Memory',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.forest),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category filter chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _categories.map((cat) {
                    final selected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AnimatedScaleButton(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.forest : AppTheme.paper,
                            borderRadius: BorderRadius.circular(AppTheme.radius18),
                            border: Border.all(color: selected ? AppTheme.forest : AppTheme.divider),
                            boxShadow: selected ? AppTheme.softShadow : [],
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                              color: selected ? Colors.white : AppTheme.deepForest,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Memory Cards List or Empty State
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppTheme.sage.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            size: 46,
                            color: AppTheme.forest,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Memories Added Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.deepForest,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Caretakers can add real family photos, stories, and voice recall questions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _showAddMemoryDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.forest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius18),
                            ),
                          ),
                          icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                          label: const Text('Add First Memory', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final mem = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AnimatedScaleButton(
                        onTap: () => _openStoryModal(mem),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.paper,
                            borderRadius: BorderRadius.circular(AppTheme.radius24),
                            boxShadow: AppTheme.softShadow,
                            border: Border.all(color: AppTheme.divider, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: mem.color,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(mem.icon, color: AppTheme.forest, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mem.title,
                                          style: const TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.deepForest,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          mem.subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.psychology_rounded, color: AppTheme.warmAmber, size: 26),
                                    tooltip: 'Start Voice Recall Quiz',
                                    onPressed: () => _startMemoryVoiceRecall(mem),
                                  ),
                                ],
                              ),
                              if (mem.taggedPersons.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: mem.taggedPersons.map((p) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sage,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.forest),
                                          const SizedBox(width: 4),
                                          Text(
                                            p,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.forest,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.cream,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.help_outline_rounded, size: 16, color: AppTheme.deepForest),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Quiz: "${mem.recallQuestion}"',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.deepForest,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
          ],
        ),
      ),
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
