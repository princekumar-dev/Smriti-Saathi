import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/local/local_store.dart';
import '../data/local/sync_fields.dart';
import 'api_service.dart';

/// Binds one Hive collection to its remote CRUD on [ApiService].
class _CollectionBinding {
  final String box;
  final Future<List<Map<String, dynamic>>> Function(String? since) fetch;
  final Future<bool> Function(Map<String, dynamic> record) save;
  final Future<bool> Function(String id) remoteDelete;

  const _CollectionBinding({
    required this.box,
    required this.fetch,
    required this.save,
    required this.remoteDelete,
  });
}

/// The offline-first outbox engine.
///
/// - [pushPending] flushes every dirty/tombstoned record to MongoDB and
///   **clears the dirty flag / drops the tombstone only after the server
///   confirms** (HTTP 2xx). A failed push leaves the record pending so it is
///   retried on the next trigger — nothing is ever lost.
/// - [pullFresh] pulls each collection incrementally (`?since=`) and merges by
///   last-write-wins, never clobbering a locally-dirty record.
/// - [syncAll] runs pull then push and updates [status] / [pendingCount].
///
/// Triggers: app start (if online), reconnect (via ConnectivityService),
/// debounced after local writes (via repositories' [pushOne]), manual retry.
class SyncService extends ChangeNotifier {
  SyncService._internal();
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;

  final LocalStore _store = LocalStore();
  final ApiService _api = ApiService();

  SyncStatus _status = SyncStatus.synced;
  SyncStatus get status => _status;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  bool _syncing = false;
  bool get isSyncing => _syncing;

  Timer? _debounce;

  late final List<_CollectionBinding> _bindings = [
    _CollectionBinding(
      box: LocalStore.boxMemories,
      fetch: (since) => _api.fetchMemories(since: since),
      save: (r) => _api.saveMemory(_stripSyncMeta(r)),
      remoteDelete: (id) => _api.deleteMemory(id),
    ),
    _CollectionBinding(
      box: LocalStore.boxFamily,
      fetch: (since) => _api.fetchFamilyMembers(since: since),
      save: (r) => _api.saveFamilyMember(_stripSyncMeta(r)),
      remoteDelete: (id) => _api.deleteFamilyMember(id),
    ),
    _CollectionBinding(
      box: LocalStore.boxReminders,
      fetch: (since) => _api.fetchReminders(since: since),
      save: (r) => _api.saveReminder(_stripSyncMeta(r)),
      remoteDelete: (id) => _api.deleteReminder(id),
    ),
    _CollectionBinding(
      box: LocalStore.boxGameScores,
      fetch: (since) => _api.fetchGameScores(since: since),
      save: (r) => _api.saveGameScore(_stripSyncMeta(r)),
      remoteDelete: (id) => _api.deleteGameScore(id),
    ),
  ];

  /// Recomputes [pendingCount] across all synced boxes and refreshes [status].
  void refreshPending() {
    if (!_store.isReady) return;
    int count = 0;
    for (final name in LocalStore.syncedBoxes) {
      for (final r in _store.readAll(name)) {
        if (isPending(r)) count++;
      }
    }
    _pendingCount = count;
    if (!_syncing) {
      _status = count > 0 ? SyncStatus.pending : SyncStatus.synced;
    }
    notifyListeners();
  }

  /// Pull fresh, then push pending. Safe to call repeatedly; no-ops if already
  /// syncing or offline.
  Future<void> syncAll() async {
    if (_syncing) return;
    if (!_store.isReady) return;
    if (!_api.isOnline) {
      // A stale flag is fine — attempt anyway; the transport flips it.
      final ok = await _api.checkHealth();
      if (!ok) {
        refreshPending();
        return;
      }
    }
    _syncing = true;
    _status = SyncStatus.syncing;
    notifyListeners();
    try {
      await pullFresh();
      await pushPending();
      refreshPending();
      _status = _pendingCount > 0 ? SyncStatus.pending : SyncStatus.synced;
    } catch (e) {
      debugPrint('SyncService.syncAll error: $e');
      _status = SyncStatus.error;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Pushes every dirty record and replays every tombstone. Clears the dirty
  /// flag / removes the tombstone **only** on a confirmed server write.
  Future<void> pushPending() async {
    for (final b in _bindings) {
      final records = _store.readAll(b.box);
      for (final record in records) {
        if (!isPending(record)) continue;
        final id = record[kId]?.toString();
        if (id == null || id.isEmpty) continue;

        if (isTombstone(record)) {
          final ok = await b.remoteDelete(id);
          if (ok) {
            await _store.remove(b.box, id); // drop tombstone after DELETE
          }
        } else {
          final ok = await b.save(record);
          if (ok) {
            // Re-read in case the record changed mid-push; clear only if the
            // updatedAt still matches what we pushed (no newer local edit).
            final current = _store.read(b.box, id);
            if (current != null &&
                updatedAtMs(current) == updatedAtMs(record) &&
                !isTombstone(current)) {
              await _store.put(b.box, id, clearDirty(current));
            }
          }
        }
      }
    }
  }

  /// Best-effort push of a single record right after a local write (online).
  Future<void> pushOne(String box, String id) async {
    if (!_api.isOnline) return;
    final binding = _bindingFor(box);
    if (binding == null) return;
    final record = _store.read(box, id);
    if (record == null || !isPending(record)) return;
    try {
      if (isTombstone(record)) {
        if (await binding.remoteDelete(id)) {
          await _store.remove(box, id);
        }
      } else {
        if (await binding.save(record)) {
          final current = _store.read(box, id);
          if (current != null &&
              updatedAtMs(current) == updatedAtMs(record) &&
              !isTombstone(current)) {
            await _store.put(box, id, clearDirty(current));
          }
        }
      }
    } catch (e) {
      debugPrint('SyncService.pushOne($box/$id) error: $e');
    }
    refreshPending();
  }

  /// Pulls each collection incrementally and merges by last-write-wins.
  Future<void> pullFresh() async {
    for (final b in _bindings) {
      final lastMs = _store.lastPulledMs(b.box);
      final since = lastMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(lastMs).toUtc().toIso8601String()
          : null;
      final remote = await b.fetch(since);
      int maxSeen = lastMs;
      for (final raw in remote) {
        final incoming = normalizeRemote(raw);
        final id = incoming[kId]?.toString();
        if (id == null || id.isEmpty) continue;
        maxSeen = maxSeen < updatedAtMs(incoming) ? updatedAtMs(incoming) : maxSeen;

        final local = _store.read(b.box, id);
        // Never clobber a record with unpushed local changes.
        if (local != null && isPending(local)) continue;

        // Last-write-wins: only overwrite if the server copy is newer.
        if (local == null || updatedAtMs(incoming) >= updatedAtMs(local)) {
          if (incoming[kDeleted] == true) {
            await _store.remove(b.box, id); // server soft-deleted → drop local
          } else {
            await _store.put(b.box, id, incoming);
          }
        }
      }
      if (maxSeen > lastMs) {
        await _store.setLastPulledMs(b.box, maxSeen);
      }
    }
  }

  /// Debounced full sync — call after a burst of local writes.
  void requestSyncDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => unawaited(syncAll()));
  }

  _CollectionBinding? _bindingFor(String box) {
    for (final b in _bindings) {
      if (b.box == box) return b;
    }
    return null;
  }

  /// Removes local-only sync metadata before sending a record to the server.
  /// (The server maintains its own `updatedAt`/`deleted`; `dirty` is purely
  /// local.) Domain fields and `id`/`patientId` are preserved.
  static Map<String, dynamic> _stripSyncMeta(Map<String, dynamic> record) {
    final copy = Map<String, dynamic>.from(record);
    copy.remove(kDirty);
    return copy;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
