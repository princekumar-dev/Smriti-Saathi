import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../data/local/sync_fields.dart';
import '../data/repositories/memory_repository.dart';
import 'memory_graph_seeder.dart';

/// Canonical memory categories (match the Memories screen tabs).
const List<String> kMemoryCategories = ['People', 'Places', 'Objects', 'Moments'];

/// Model representing a rich senior memory with caretaker tagging and AI recall
/// questions. Persisted offline-first as a JSON-safe map (see [toMap] /
/// [fromMap]); `icon`/`color` are derived at read time, never stored.
class MemoryItem {
  final String id;
  final String title;
  final String subtitle;
  final String category; // People | Places | Objects | Moments
  final String description;
  final String event;
  final List<String> taggedPersons;
  final String? mediaPath; // local gallery file path, asset, or url
  final String? audioPath; // optional recorded voice note (local file)
  final bool isVideo;
  final bool favorite;
  final IconData icon; // derived, not persisted
  final Color color; // derived, not persisted
  final String recallQuestion;
  final String recallAnswer;
  final List<String> alternativeAnswers;
  final String reminiscenceStory;
  final DateTime createdAt;

  const MemoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.description,
    required this.event,
    required this.taggedPersons,
    this.mediaPath,
    this.audioPath,
    this.isVideo = false,
    this.favorite = false,
    this.icon = Icons.photo_library_rounded,
    this.color = const Color(0xFFE7F0E9),
    required this.recallQuestion,
    required this.recallAnswer,
    this.alternativeAnswers = const [],
    required this.reminiscenceStory,
    required this.createdAt,
  });

  /// True when [mediaPath] points at an on-device file (gallery pick / camera)
  /// rather than a bundled asset or remote url.
  bool get hasLocalImage {
    final p = mediaPath;
    if (p == null || p.isEmpty) return false;
    return !p.startsWith('http') && !p.startsWith('assets/');
  }

  /// JSON-safe map for Hive + MongoDB (no icon/color — those are derived).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'description': description,
      'event': event,
      'taggedPersons': taggedPersons,
      'mediaPath': mediaPath,
      'audioPath': audioPath,
      'isVideo': isVideo,
      'favorite': favorite,
      'recallQuestion': recallQuestion,
      'recallAnswer': recallAnswer,
      'alternativeAnswers': alternativeAnswers,
      'reminiscenceStory': reminiscenceStory,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Rebuilds a [MemoryItem] from a stored/remote map, deriving icon+color.
  factory MemoryItem.fromMap(Map<String, dynamic> item) {
    final category = _normalizeCategory(item['category']?.toString() ?? 'Moments');
    final isVideo = item['isVideo'] == true;
    return MemoryItem(
      id: item['id']?.toString() ?? MemoryRepository.newId(),
      title: item['title']?.toString() ?? 'Untitled Memory',
      subtitle: item['subtitle']?.toString() ?? '',
      category: category,
      event: item['event']?.toString() ?? '',
      taggedPersons:
          (item['taggedPersons'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      description: item['description']?.toString() ?? '',
      mediaPath: (item['mediaPath']?.toString().isNotEmpty ?? false)
          ? item['mediaPath'].toString()
          : null,
      audioPath: (item['audioPath']?.toString().isNotEmpty ?? false)
          ? item['audioPath'].toString()
          : null,
      isVideo: isVideo,
      favorite: item['favorite'] == true,
      icon: isVideo ? Icons.play_circle_fill_rounded : _iconForCategory(category),
      color: _colorForCategory(category),
      recallQuestion: item['recallQuestion']?.toString() ?? '',
      recallAnswer: item['recallAnswer']?.toString() ?? '',
      alternativeAnswers:
          (item['alternativeAnswers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      reminiscenceStory: item['reminiscenceStory']?.toString() ?? '',
      createdAt: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  MemoryItem copyWith({bool? favorite, String? mediaPath, String? audioPath}) {
    return MemoryItem(
      id: id,
      title: title,
      subtitle: subtitle,
      category: category,
      description: description,
      event: event,
      taggedPersons: taggedPersons,
      mediaPath: mediaPath ?? this.mediaPath,
      audioPath: audioPath ?? this.audioPath,
      isVideo: isVideo,
      favorite: favorite ?? this.favorite,
      icon: icon,
      color: color,
      recallQuestion: recallQuestion,
      recallAnswer: recallAnswer,
      alternativeAnswers: alternativeAnswers,
      reminiscenceStory: reminiscenceStory,
      createdAt: createdAt,
    );
  }

  static String _normalizeCategory(String raw) {
    final c = raw.toLowerCase();
    if (c.contains('people') || c.contains('family') || c.contains('person')) return 'People';
    if (c.contains('place') || c.contains('home') || c.contains('travel')) return 'Places';
    if (c.contains('object') || c.contains('thing') || c.contains('item')) return 'Objects';
    if (c.contains('moment') || c.contains('festival') || c.contains('childhood') || c.contains('milestone')) {
      return 'Moments';
    }
    // Keep an already-canonical value; otherwise default to Moments.
    return kMemoryCategories.contains(raw) ? raw : 'Moments';
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'People':
        return Icons.people_alt_rounded;
      case 'Places':
        return Icons.cottage_rounded;
      case 'Objects':
        return Icons.category_rounded;
      case 'Moments':
      default:
        return Icons.celebration_rounded;
    }
  }

  static Color _colorForCategory(String category) {
    switch (category) {
      case 'People':
        return const Color(0xFFE9E5F2);
      case 'Places':
        return const Color(0xFFF5E6DD);
      case 'Objects':
        return const Color(0xFFF3EAD7);
      case 'Moments':
      default:
        return const Color(0xFFE7F0E9);
    }
  }
}

/// Global Service for managing Memories, Media Permissions, and AI Recall
/// Questions. Offline-first: all reads/writes flow through [MemoryRepository]
/// (Hive), which best-effort syncs to MongoDB when online.
class MemoryService extends ChangeNotifier {
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  MemoryService._internal() {
    _repo.addListener(_reload);
    _reload();
    // Pull anything newer from the backend in the background (no-op offline).
    refreshFromRemote();
  }

  final MemoryRepository _repo = MemoryRepository();
  final ImagePicker _picker = ImagePicker();

  bool _hasPhotoPermission = false;
  bool _hasVideoPermission = false;
  bool _permissionChecked = false;

  bool get hasPhotoPermission => _hasPhotoPermission;
  bool get hasVideoPermission => _hasVideoPermission;
  bool get permissionChecked => _permissionChecked;

  List<MemoryItem> _memories = [];
  List<MemoryItem> get memories => List.unmodifiable(_memories);

  /// The senior currently in context (used to tag new memories); optional.
  String? patientId;

  /// The senior's display name, used to root the memory graph on their "self"
  /// node when a new memory is captured. Set by screens that know the patient.
  String selfName = '';

  int _recallScore = 0;
  int get recallScore => _recallScore;

  /// Rebuilds the in-memory list from the local Hive store (instant, offline).
  void _reload() {
    _memories = _repo
        .getAll(patientId: patientId)
        .map((m) => MemoryItem.fromMap(m))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  /// Kept for backwards compatibility with existing callers.
  Future<void> loadFromDatabase() => refreshFromRemote();

  /// Pulls fresh memories from MongoDB (when online) into the local store.
  Future<void> refreshFromRemote() async {
    try {
      await _repo.refreshFromRemote();
      _reload();
    } catch (e) {
      debugPrint('MemoryService.refreshFromRemote error: $e');
    }
  }

  /// Request permissions for Photos & Videos.
  Future<bool> requestMediaPermissions() async {
    if (kIsWeb) {
      _hasPhotoPermission = true;
      _hasVideoPermission = true;
      _permissionChecked = true;
      notifyListeners();
      return true;
    }
    try {
      final photosStatus = await Permission.photos.request();
      final storageStatus = await Permission.storage.request();
      final videosStatus = await Permission.videos.request();
      _hasPhotoPermission = photosStatus.isGranted || storageStatus.isGranted;
      _hasVideoPermission = videosStatus.isGranted || storageStatus.isGranted;
      _permissionChecked = true;
      notifyListeners();
      return _hasPhotoPermission || _hasVideoPermission;
    } catch (e) {
      _hasPhotoPermission = true;
      _hasVideoPermission = true;
      _permissionChecked = true;
      notifyListeners();
      return true;
    }
  }

  /// Opens the system gallery (or camera) and returns a **persistent** local
  /// file path — the picked image is copied into the app's documents dir so it
  /// survives even if the original is cleared from the OS cache. Returns null
  /// if the user cancels.
  Future<String?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return null;
      return await _persistPickedFile(picked);
    } catch (e) {
      debugPrint('MemoryService.pickImage error: $e');
      return null;
    }
  }

  Future<String> _persistPickedFile(XFile picked) async {
    try {
      if (kIsWeb) return picked.path; // web returns a usable blob url
      final dir = await getApplicationDocumentsDirectory();
      final memDir = Directory('${dir.path}/memory_media');
      if (!await memDir.exists()) await memDir.create(recursive: true);
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      final dest = '${memDir.path}/mem_${nowMs()}.$ext';
      await File(picked.path).copy(dest);
      return dest;
    } catch (e) {
      debugPrint('MemoryService._persistPickedFile error: $e');
      return picked.path; // fall back to the original path
    }
  }

  /// Caretaker adds a customized memory (optionally with a gallery photo).
  Future<MemoryItem> addMemory({
    required String title,
    required String subtitle,
    required String category,
    required String event,
    required List<String> taggedPersons,
    required String description,
    required String recallQuestion,
    required String recallAnswer,
    required List<String> alternativeAnswers,
    required String reminiscenceStory,
    String? mediaPath,
    String? audioPath,
    bool isVideo = false,
  }) async {
    final item = MemoryItem(
      id: MemoryRepository.newId(),
      title: title,
      subtitle: subtitle,
      category: MemoryItem._normalizeCategory(category),
      event: event,
      taggedPersons: taggedPersons,
      description: description,
      recallQuestion: recallQuestion,
      recallAnswer: recallAnswer,
      alternativeAnswers: alternativeAnswers,
      reminiscenceStory: reminiscenceStory,
      mediaPath: mediaPath,
      audioPath: audioPath,
      isVideo: isVideo,
      createdAt: DateTime.now(),
    );
    final map = item.toMap();
    if (patientId != null) map[kPatientId] = patientId;
    await _repo.upsert(map); // writes Hive (dirty) + best-effort push
    // Grow the personal memory graph immediately so Saathi "knows" this the
    // moment it's captured — people/places/events become connected nodes.
    try {
      await MemoryGraphSeeder().seedOne(item, selfName: selfName);
    } catch (e) {
      debugPrint('MemoryService.addMemory graph seed error: $e');
    }
    return item;
  }

  /// Toggle the favorite (heart) flag on a memory.
  Future<void> toggleFavorite(String id) => _repo.toggleFavorite(id);

  /// Delete a memory (tombstoned locally, DELETE replayed when online).
  Future<void> deleteMemory(String id) => _repo.delete(id);

  /// Memories in one display category tab; pass 'All' for everything.
  List<MemoryItem> byCategory(String category) {
    if (category == 'All') return memories;
    return _memories.where((m) => m.category == category).toList();
  }

  /// Get a memory recall challenge for the elderly patient.
  MemoryItem? getRandomRecallMemory() {
    if (_memories.isEmpty) return null;
    final shuffled = List<MemoryItem>.from(_memories)..shuffle();
    return shuffled.first;
  }

  /// Validate Senior's answer to a memory recall question.
  bool evaluateAnswer(MemoryItem memory, String seniorAnswer) {
    final clean = seniorAnswer.trim().toLowerCase();
    if (clean.isEmpty) return false;

    final target = memory.recallAnswer.toLowerCase();
    if (target.isNotEmpty && (clean.contains(target) || target.contains(clean))) {
      _recallScore += 10;
      notifyListeners();
      return true;
    }
    for (final alt in memory.alternativeAnswers) {
      final a = alt.toLowerCase();
      if (a.isNotEmpty && (clean.contains(a) || a.contains(clean))) {
        _recallScore += 10;
        notifyListeners();
        return true;
      }
    }
    for (final person in memory.taggedPersons) {
      final pName = person.split('(').first.trim().toLowerCase();
      if (pName.isNotEmpty && clean.contains(pName)) {
        _recallScore += 10;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _repo.removeListener(_reload);
    super.dispose();
  }
}
