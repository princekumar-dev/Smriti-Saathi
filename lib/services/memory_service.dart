import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Model representing a rich senior memory with caretaker tagging and AI recall questions
class MemoryItem {
  final String id;
  final String title;
  final String subtitle;
  final String category; // 'Family', 'Places', 'Childhood', 'Festivals', 'Milestones'
  final String description;
  final String event; // e.g. "Pongal 2023", "Wedding Anniversary", "School Days"
  final List<String> taggedPersons; // e.g. ["Daughter Meena", "Son Arun", "Granddaughter Lakshmi"]
  final String? mediaPath; // Photo / Video asset or url
  final bool isVideo;
  final IconData icon;
  final Color color;
  final String recallQuestion; // Question Saathi asks the senior to stimulate memory
  final String recallAnswer; // The key answer or person name
  final List<String> alternativeAnswers; // Acceptable fuzzy answers
  final String reminiscenceStory; // Story Saathi narrates when recalling
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
    this.isVideo = false,
    this.icon = Icons.photo_library_rounded,
    this.color = const Color(0xFFE7F0E9),
    required this.recallQuestion,
    required this.recallAnswer,
    this.alternativeAnswers = const [],
    required this.reminiscenceStory,
    required this.createdAt,
  });

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
      'isVideo': isVideo,
      'icon': icon,
      'color': color,
      'recallQuestion': recallQuestion,
      'recallAnswer': recallAnswer,
      'alternativeAnswers': alternativeAnswers,
      'reminiscenceStory': reminiscenceStory,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Global Service for managing Memories, Media Permissions, and AI Recall Questions
class MemoryService extends ChangeNotifier {
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  MemoryService._internal() {
    loadFromDatabase();
  }

  bool _hasPhotoPermission = false;
  bool _hasVideoPermission = false;
  bool _permissionChecked = false;

  bool get hasPhotoPermission => _hasPhotoPermission;
  bool get hasVideoPermission => _hasVideoPermission;
  bool get permissionChecked => _permissionChecked;

  final List<MemoryItem> _memories = [];
  List<MemoryItem> get memories => List.unmodifiable(_memories);

  int _recallScore = 0;
  int get recallScore => _recallScore;

  /// Fetch real memories from MongoDB Atlas via ApiService
  Future<void> loadFromDatabase() async {
    try {
      final data = await ApiService().fetchMemories();
      if (data.isNotEmpty) {
        _memories.clear();
        for (final item in data) {
          _memories.add(
            MemoryItem(
              id: item['id']?.toString() ?? 'mem_${DateTime.now().millisecondsSinceEpoch}',
              title: item['title']?.toString() ?? 'Untitled Memory',
              subtitle: item['subtitle']?.toString() ?? '',
              category: item['category']?.toString() ?? 'General',
              event: item['event']?.toString() ?? '',
              taggedPersons: (item['taggedPersons'] as List?)?.map((e) => e.toString()).toList() ?? [],
              description: item['description']?.toString() ?? '',
              mediaPath: item['mediaPath']?.toString(),
              isVideo: item['isVideo'] == true,
              icon: (item['isVideo'] == true) ? Icons.video_library_rounded : Icons.photo_library_rounded,
              color: _getCategoryColor(item['category']?.toString() ?? 'General'),
              recallQuestion: item['recallQuestion']?.toString() ?? '',
              recallAnswer: item['recallAnswer']?.toString() ?? '',
              alternativeAnswers: (item['alternativeAnswers'] as List?)?.map((e) => e.toString()).toList() ?? [],
              reminiscenceStory: item['reminiscenceStory']?.toString() ?? '',
              createdAt: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
            ),
          );
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('MemoryService.loadFromDatabase error: $e');
    }
  }

  /// Request permissions for Photos & Videos
  Future<bool> requestMediaPermissions() async {
    if (kIsWeb) {
      // In browser web, user granting file selection / media is granted by browser
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

  /// Caretaker adds a new customized memory with tagged person and AI recall question
  void addMemory({
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
    bool isVideo = false,
  }) {
    final newMem = MemoryItem(
      id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      category: category,
      event: event,
      taggedPersons: taggedPersons,
      description: description,
      recallQuestion: recallQuestion,
      recallAnswer: recallAnswer,
      alternativeAnswers: alternativeAnswers,
      reminiscenceStory: reminiscenceStory,
      mediaPath: mediaPath,
      isVideo: isVideo,
      icon: isVideo ? Icons.video_library_rounded : Icons.photo_library_rounded,
      color: _getCategoryColor(category),
      createdAt: DateTime.now(),
    );

    _memories.insert(0, newMem);
    notifyListeners();

    // Persist to MongoDB Atlas asynchronously
    ApiService().saveMemory(newMem.toMap()).then((ok) {
      if (ok) debugPrint('Memory ${newMem.id} saved to MongoDB Atlas');
    });
  }

  /// Delete memory from local state and MongoDB Atlas
  Future<void> deleteMemory(String id) async {
    _memories.removeWhere((m) => m.id == id);
    notifyListeners();
    await ApiService().deleteMemory(id);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'family':
        return const Color(0xFFE9E5F2);
      case 'places':
        return const Color(0xFFF5E6DD);
      case 'festivals':
        return const Color(0xFFF3EAD7);
      case 'childhood':
        return const Color(0xFFE7F0E9);
      default:
        return const Color(0xFFE7F0E9);
    }
  }

  /// Get a memory recall challenge for the elderly patient
  MemoryItem? getRandomRecallMemory() {
    if (_memories.isEmpty) return null;
    final shuffled = List<MemoryItem>.from(_memories)..shuffle();
    return shuffled.first;
  }

  /// Validate Senior's answer to a memory recall question
  bool evaluateAnswer(MemoryItem memory, String seniorAnswer) {
    final clean = seniorAnswer.trim().toLowerCase();
    if (clean.isEmpty) return false;

    final target = memory.recallAnswer.toLowerCase();
    if (clean.contains(target) || target.contains(clean)) {
      _recallScore += 10;
      notifyListeners();
      return true;
    }

    for (final alt in memory.alternativeAnswers) {
      if (clean.contains(alt.toLowerCase()) || alt.toLowerCase().contains(clean)) {
        _recallScore += 10;
        notifyListeners();
        return true;
      }
    }

    for (final person in memory.taggedPersons) {
      final pName = person.split('(').first.trim().toLowerCase();
      if (clean.contains(pName)) {
        _recallScore += 10;
        notifyListeners();
        return true;
      }
    }

    return false;
  }
}
