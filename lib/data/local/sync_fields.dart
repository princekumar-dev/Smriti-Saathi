/// Sync metadata helpers shared by every offline-first Hive record.
///
/// Every synced record is a plain `Map<String, dynamic>` (no TypeAdapters —
/// Hive stores primitive maps/lists directly) carrying three sync fields on
/// top of its domain fields:
///
/// ```
/// { ...domainFields, 'id': 'mem_1699...', 'patientId': '...',
///   'updatedAt': <ms int>, 'dirty': true/false, 'deleted': true/false }
/// ```
///
/// - [kDirty]   = has unpushed local changes.
/// - [kDeleted] = tombstone: replay DELETE to the server, then drop locally.
/// - [kUpdatedAt] = last local mutation, epoch millis; drives last-write-wins.
library;

/// Record key names — kept as constants so callers never typo them.
const String kId = 'id';
const String kPatientId = 'patientId';
const String kUpdatedAt = 'updatedAt';
const String kDirty = 'dirty';
const String kDeleted = 'deleted';

/// Overall sync state surfaced to the UI (badge / indicator).
enum SyncStatus {
  /// Local store matches the server (no pending records).
  synced,

  /// A push/pull is currently in flight.
  syncing,

  /// There are dirty/tombstoned records waiting to be pushed.
  pending,

  /// The last sync attempt failed (will retry on next trigger).
  error,

  /// Sync is disabled — forced offline via AppSettings.offlineMode.
  offline,
}

/// Epoch millis "now", the unit stored in [kUpdatedAt].
int nowMs() => DateTime.now().millisecondsSinceEpoch;

/// Returns a copy of [record] stamped as a fresh local write:
/// `updatedAt = now`, `dirty = true`, `deleted` preserved (defaults false).
Map<String, dynamic> markDirty(Map<String, dynamic> record) {
  final copy = Map<String, dynamic>.from(record);
  copy[kUpdatedAt] = nowMs();
  copy[kDirty] = true;
  copy[kDeleted] = copy[kDeleted] == true;
  return copy;
}

/// Returns a copy of [record] marked as a tombstone: `deleted = true`,
/// `dirty = true`, `updatedAt = now`. The DELETE is replayed on next push,
/// then the record is dropped locally.
Map<String, dynamic> markDeleted(Map<String, dynamic> record) {
  final copy = Map<String, dynamic>.from(record);
  copy[kUpdatedAt] = nowMs();
  copy[kDirty] = true;
  copy[kDeleted] = true;
  return copy;
}

/// Returns a copy of [record] with [kUpdatedAt] set to now (leaves flags).
Map<String, dynamic> stampUpdatedAt(Map<String, dynamic> record) {
  final copy = Map<String, dynamic>.from(record);
  copy[kUpdatedAt] = nowMs();
  return copy;
}

/// Returns a copy of [record] with `dirty = false` — call this only after a
/// successful server push.
Map<String, dynamic> clearDirty(Map<String, dynamic> record) {
  final copy = Map<String, dynamic>.from(record);
  copy[kDirty] = false;
  return copy;
}

/// True if [record] has local changes not yet pushed (dirty or tombstoned).
bool isPending(Map<String, dynamic> record) => record[kDirty] == true;

/// True if [record] is a tombstone awaiting a replayed DELETE.
bool isTombstone(Map<String, dynamic> record) => record[kDeleted] == true;

/// The record's updatedAt as epoch millis, tolerant of int / num / ISO string
/// / Mongo Date shapes coming back from the server.
int updatedAtMs(Map<String, dynamic> record) => coerceMs(record[kUpdatedAt]);

/// Coerces a variety of timestamp encodings to epoch millis.
///
/// Handles: `int`/`num` (already millis), ISO-8601 `String`, and Mongo's
/// extended-JSON `{ "\$date": ... }`. Returns 0 when unparseable.
int coerceMs(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.millisecondsSinceEpoch;
    final asInt = int.tryParse(value);
    if (asInt != null) return asInt;
    return 0;
  }
  if (value is Map) {
    final d = value[r'$date'];
    if (d != null) return coerceMs(d);
  }
  return 0;
}

/// Normalizes a record coming from the server so it carries our sync fields
/// with local-friendly types (updatedAt as epoch millis, dirty=false since it
/// just arrived clean from the server, deleted from the server's soft-delete
/// flag).
Map<String, dynamic> normalizeRemote(Map<String, dynamic> remote) {
  final copy = Map<String, dynamic>.from(remote);
  copy[kUpdatedAt] = coerceMs(remote[kUpdatedAt]);
  copy[kDirty] = false;
  copy[kDeleted] = remote[kDeleted] == true;
  return copy;
}
