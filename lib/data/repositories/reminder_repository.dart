import '../local/local_store.dart';
import 'synced_repository.dart';

/// Offline-first store for routine reminders (plain maps, keyed by `id`).
class ReminderRepository extends SyncedRepository {
  ReminderRepository._() : super(LocalStore.boxReminders);
  static final ReminderRepository _instance = ReminderRepository._();
  factory ReminderRepository() => _instance;
}
