import '../local/local_store.dart';
import '../local/sync_fields.dart';
import 'synced_repository.dart';

/// Offline-first store for game scores / streaks (plain maps, keyed by `id`).
///
/// A score record looks like:
/// ```
/// { 'id': 'score_...', 'patientId': '...', 'game': 'memory_match',
///   'score': 120, 'streak': 3, 'playedAt': <ms int>, ...sync fields }
/// ```
class GameScoreRepository extends SyncedRepository {
  GameScoreRepository._() : super(LocalStore.boxGameScores);
  static final GameScoreRepository _instance = GameScoreRepository._();
  factory GameScoreRepository() => _instance;

  /// Records a completed round for [game], returning the saved record.
  Future<Map<String, dynamic>> recordScore({
    required String game,
    required int score,
    String? patientId,
    int? stars,
    Map<String, dynamic> extra = const {},
  }) async {
    final now = nowMs();
    final record = <String, dynamic>{
      kId: 'score_${game}_$now',
      if (patientId != null) kPatientId: patientId,
      'game': game,
      'score': score,
      if (stars != null) 'stars': stars,
      'playedAt': now,
      ...extra,
    };
    await upsert(record);
    return record;
  }

  /// Best score recorded for [game] (0 if never played).
  int bestScore(String game, {String? patientId}) {
    int best = 0;
    for (final r in getAll(patientId: patientId)) {
      if (r['game'] == game) {
        final s = (r['score'] as num?)?.toInt() ?? 0;
        if (s > best) best = s;
      }
    }
    return best;
  }

  /// Total number of rounds played for [game].
  int timesPlayed(String game, {String? patientId}) {
    return getAll(patientId: patientId).where((r) => r['game'] == game).length;
  }
}
