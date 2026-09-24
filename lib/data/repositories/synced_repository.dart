import 'package:flutter/foundation.dart';

import '../local/local_store.dart';
import '../local/sync_fields.dart';
import '../../services/sync_service.dart';

/// Shared offline-first repository over one Hive box.
///
/// Screens read and write **only** through repositories — never `ApiService`
/// directly. Every write lands in Hive first (stamped `dirty=true`), so it
/// survives offline and app restarts; when online we best-effort push it right
/// away, and [SyncService] retries anything that didn't stick.
///
/// Follows the app's "local first, backend when available" precedent
/// (see AuthState.loginCaretaker).
class SyncedRepository extends ChangeNotifier {
  SyncedRepository(this.boxName, {this.synced = true});

  /// The Hive box this repository owns (see [LocalStore] box constants).
  final String boxName;

  /// When false, records are persisted locally but never marked dirty / pushed
  /// (used for chat history, which has no server endpoint).
  final bool synced;

  final LocalStore _store = LocalStore();

  /// All live (non-tombstone) records, newest first by `updatedAt`.
  List<Map<String, dynamic>> getAll({String? patientId}) {
    if (!_store.isReady) return const [];
    final list = _store
        .readAll(boxName)
        .where((r) => r[kDeleted] != true)
        .where((r) => patientId == null || r[kPatientId] == null || r[kPatientId] == patientId)
        .toList();
    list.sort((a, b) => updatedAtMs(b).compareTo(updatedAtMs(a)));
    return list;
  }

  /// A single record by id (null if missing or tombstoned).
  Map<String, dynamic>? getById(String id) {
    final r = _store.read(boxName, id);
    if (r == null || r[kDeleted] == true) return null;
    return r;
  }

  /// Inserts or updates [record] (must carry an `id`). Writes locally as dirty,
  /// then best-effort pushes when online.
  Future<void> upsert(Map<String, dynamic> record) async {
    final id = record[kId]?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('upsert requires a non-empty "id" field');
    }
    final stamped = synced ? markDirty(record) : _localClean(record);
    await _store.put(boxName, id, stamped);
    notifyListeners();
    if (synced) {
      unawaited_(SyncService().pushOne(boxName, id));
    }
  }

  /// Marks [id] deleted (tombstone). When online the DELETE is replayed and the
  /// record dropped; offline it stays as a tombstone until reconnect.
  Future<void> delete(String id) async {
    final existing = _store.read(boxName, id);
    if (existing == null) return;
    if (!synced) {
      await _store.remove(boxName, id);
      notifyListeners();
      return;
    }
    await _store.put(boxName, id, markDeleted(existing));
    notifyListeners();
    unawaited_(SyncService().pushOne(boxName, id));
  }

  /// Triggers a full pull+push if online (repositories notify on completion via
  /// [SyncService]'s own listeners; callers can also await this).
  Future<void> refreshFromRemote() async {
    if (!synced) return;
    await SyncService().syncAll();
    notifyListeners();
  }

  Map<String, dynamic> _localClean(Map<String, dynamic> record) {
    final copy = Map<String, dynamic>.from(record);
    copy[kUpdatedAt] = nowMs();
    copy[kDirty] = false;
    copy[kDeleted] = copy[kDeleted] == true;
    return copy;
  }

  // Local fire-and-forget without importing dart:async at every call site.
  void unawaited_(Future<void> f) {
    f.catchError((e) => debugPrint('$boxName push error: $e'));
  }
}
