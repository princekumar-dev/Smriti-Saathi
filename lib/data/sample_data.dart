import 'package:flutter/material.dart';

class SampleData {
  // ------------------------------------------------------------
  // MEMORIES (Clean state - populated by user or synced from MongoDB)
  // ------------------------------------------------------------

  static final List<Map<String, dynamic>> memories = [];

  // ------------------------------------------------------------
  // FAMILY (Clean state - populated by caretaker or synced from MongoDB)
  // ------------------------------------------------------------

  static final List<Map<String, dynamic>> familyMembers = [];

  // ------------------------------------------------------------
  // ROUTINE (Clean state - populated by user or synced from MongoDB)
  // ------------------------------------------------------------

  static final List<Map<String, dynamic>> reminders = [];

  // ------------------------------------------------------------
  // ACTIVITIES
  // ------------------------------------------------------------

  static final List<Map<String, dynamic>> activities = [
    {
      'id': 'activity_001',
      'title': 'Memory Match',
      'description': 'Match familiar things',
      'duration': '5 min',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFFE7F0E9),
    },
    {
      'id': 'activity_002',
      'title': 'Remember & Tell',
      'description': 'Talk about a memory',
      'duration': '10 min',
      'icon': Icons.question_mark_rounded,
      'color': const Color(0xFFF5E6DD),
    },
    {
      'id': 'activity_003',
      'title': 'Familiar Music',
      'description': 'Listen and remember',
      'duration': '10 min',
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFFE9E5F2),
    },
    {
      'id': 'activity_004',
      'title': 'Finish the Story',
      'description': 'Complete a simple story',
      'duration': '5 min',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFFF3EAD7),
    },
  ];
}