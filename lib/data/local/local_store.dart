import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Central handle to the app's on-device Hive store.
///
/// Every synced collection is a Hive box of plain `Map<String, dynamic>`
/// records keyed by the record's client-assigned string `id` (the same id the
/// MongoDB server upserts on). No TypeAdapters / build_runner — records stay as
/// primitive maps to match the app's existing Map/JSON handling.
///
/// Call [init] once from `main()` before `runApp`.
class LocalStore {
  LocalStore._internal();
  static final LocalStore _instance = LocalStore._internal();
  factory LocalStore() => _instance;

  // Box names — also the collection identifiers used across sync.
  static const String boxMemories = 'memories';
  static const String boxFamily = 'family';
  static const String boxReminders = 'reminders';
  static const String boxChatHistory = 'chat_history';
  static const String boxGameScores = 'game_scores';
  static const String boxSyncMeta = 'sync_meta';

  // Memory-graph boxes — local-only for now (no server endpoints yet), like
  // chat history. Nodes = people/places/events…, edges = their relationships.
  static const String boxGraphNodes = 'graph_nodes';
  static const String boxGraphEdges = 'graph_edges';

  /// Boxes persisted on-device but not pushed to the backend.
  static const List<String> localOnlyBoxes = [
    boxGraphNodes,
    boxGraphEdges,
  ];

  /// The synced data boxes (excludes [boxSyncMeta], which is bookkeeping).
  static const List<String> syncedBoxes = [
    boxMemories,
    boxFamily,
    boxReminders,
    boxChatHistory,
    boxGameScores,
  ];

  bool _ready = false;
  bool get isReady => _ready;

  /// Opens Hive and every box. Idempotent.
  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    for (final name in [...syncedBoxes, ...localOnlyBoxes, boxSyncMeta]) {
      if (!Hive.isBoxOpen(name)) {
        await Hive.openBox<dynamic>(name);
      }
    }
    _ready = true;
    debugPrint('LocalStore ready — boxes: '
        '${[...syncedBoxes, ...localOnlyBoxes, boxSyncMeta]}');
  }

  /// The box for a synced collection. Assumes [init] has run.
  Box<dynamic> box(String name) => Hive.box<dynamic>(name);

  // ── Record access ──────────────────────────────────────────────

  /// All records in [boxName] as typed maps (raw — includes tombstones).
  List<Map<String, dynamic>> readAll(String boxName) {
    final b = box(boxName);
    return b.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// A single record by id, or null.
  Map<String, dynamic>? read(String boxName, String id) {
    final v = box(boxName).get(id);
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  /// Writes [record] under its `id`.
  Future<void> put(String boxName, String id, Map<String, dynamic> record) {
    return box(boxName).put(id, record);
  }

  /// Removes a record entirely (used to drop a tombstone after its DELETE
  /// has been successfully replayed to the server).
  Future<void> remove(String boxName, String id) {
    return box(boxName).delete(id);
  }

  // ── Sync bookkeeping (last successful pull cursor per collection) ──

  /// Millis of the last successful pull for [collection], used for `?since=`.
  int lastPulledMs(String collection) {
    final v = box(boxSyncMeta).get('lastPulled_$collection');
    return v is int ? v : 0;
  }

  Future<void> setLastPulledMs(String collection, int ms) {
    return box(boxSyncMeta).put('lastPulled_$collection', ms);
  }

  /// Clears every synced box (not used in normal flow; handy for a hard reset).
  Future<void> clearAll() async {
    for (final name in syncedBoxes) {
      await box(name).clear();
    }
    await box(boxSyncMeta).clear();
  }
}
