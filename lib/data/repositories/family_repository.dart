import '../local/local_store.dart';
import 'synced_repository.dart';

/// Offline-first store for family members (plain maps, keyed by `id`).
class FamilyRepository extends SyncedRepository {
  FamilyRepository._() : super(LocalStore.boxFamily);
  static final FamilyRepository _instance = FamilyRepository._();
  factory FamilyRepository() => _instance;
}
