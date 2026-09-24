import '../local/sync_fields.dart';
import 'graph_enums.dart';

/// A directed relationship between two [GraphNode]s — the edges that let
/// Saathi understand *connections* ("Arun is your son", "Pongal was in the
/// village") instead of treating memories as isolated entries.
///
/// Stored as a plain map in Hive with the standard sync fields.
class GraphEdge {
  final String id;
  final String fromId;
  final String toId;

  /// Human-readable relation from `from` → `to`, e.g. "son", "lives in",
  /// "celebrated at", "likes". Kept as free text so it works across cultures
  /// and languages (§19).
  final String relation;

  /// Optional inverse label ("father"/"parent") for the `to → from` direction.
  final String inverse;

  final MemoryConfidence confidence;
  final String source;

  const GraphEdge({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.relation,
    this.inverse = '',
    this.confidence = MemoryConfidence.confirmed,
    this.source = 'user',
  });

  bool get isConfirmed => confidence == MemoryConfidence.confirmed;

  Map<String, dynamic> toMap({String? patientId}) => {
        kId: id,
        if (patientId != null) kPatientId: patientId,
        'fromId': fromId,
        'toId': toId,
        'relation': relation,
        'inverse': inverse,
        'confidence': confidence.id,
        'source': source,
      };

  factory GraphEdge.fromMap(Map<String, dynamic> m) => GraphEdge(
        id: m[kId]?.toString() ?? '',
        fromId: m['fromId']?.toString() ?? '',
        toId: m['toId']?.toString() ?? '',
        relation: m['relation']?.toString() ?? '',
        inverse: m['inverse']?.toString() ?? '',
        confidence: MemoryConfidenceX.from(m['confidence'] as String?),
        source: m['source']?.toString() ?? 'user',
      );
}
