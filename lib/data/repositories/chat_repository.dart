import '../local/local_store.dart';
import '../local/sync_fields.dart';
import 'synced_repository.dart';

/// Local-only persistence for Saathi chat history.
///
/// Chat is persisted so conversations survive restarts and are available
/// offline, but it has no server endpoint — so [synced] is false: records are
/// never marked dirty or pushed, and never counted as "pending".
///
/// A message record:
/// ```
/// { 'id': 'msg_...', 'patientId': '...', 'role': 'user'|'saathi',
///   'text': '...', 'ts': <ms int>, ...local fields }
/// ```
class ChatRepository extends SyncedRepository {
  ChatRepository._() : super(LocalStore.boxChatHistory, synced: false);
  static final ChatRepository _instance = ChatRepository._();
  factory ChatRepository() => _instance;

  /// Appends a message, returning the stored record.
  Future<Map<String, dynamic>> addMessage({
    required String role,
    required String text,
    String? patientId,
  }) async {
    final now = nowMs();
    final record = <String, dynamic>{
      kId: 'msg_$now',
      if (patientId != null) kPatientId: patientId,
      'role': role,
      'text': text,
      'ts': now,
    };
    await upsert(record);
    return record;
  }

  /// Full history for [patientId], oldest first.
  List<Map<String, dynamic>> history({String? patientId}) {
    final list = getAll(patientId: patientId);
    list.sort((a, b) => coerceMs(a['ts']).compareTo(coerceMs(b['ts'])));
    return list;
  }

  /// Clears the whole conversation.
  Future<void> clear() async {
    for (final r in getAll()) {
      await delete(r[kId].toString());
    }
  }
}
