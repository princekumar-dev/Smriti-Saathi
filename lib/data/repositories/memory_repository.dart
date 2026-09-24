import '../local/local_store.dart';
import '../local/sync_fields.dart';
import 'synced_repository.dart';

/// Offline-first store for senior memories (JSON-safe plain maps, keyed by
/// `id`). Display-only fields like `icon`/`color` are derived at the UI layer
/// from `category`/`isVideo`, never persisted.
class MemoryRepository extends SyncedRepository {
  MemoryRepository._() : super(LocalStore.boxMemories);
  static final MemoryRepository _instance = MemoryRepository._();
  factory MemoryRepository() => _instance;

  /// Toggles the local "favorite" flag on a memory and re-stamps it dirty.
  Future<void> toggleFavorite(String id) async {
    final r = getById(id);
    if (r == null) return;
    final updated = Map<String, dynamic>.from(r);
    updated['favorite'] = !(r['favorite'] == true);
    await upsert(updated);
  }

  /// Memories in a display category tab (People / Places / Objects / Moments),
  /// case-insensitive; pass null/`'All'` for everything.
  List<Map<String, dynamic>> byCategory(String? category, {String? patientId}) {
    final all = getAll(patientId: patientId);
    if (category == null || category.toLowerCase() == 'all') return all;
    final c = category.toLowerCase();
    return all.where((r) => (r['category']?.toString().toLowerCase() ?? '') == c).toList();
  }

  /// Mints a client id for a brand-new memory.
  static String newId() => 'mem_${nowMs()}';
}
