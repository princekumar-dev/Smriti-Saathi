import '../local/sync_fields.dart';
import 'graph_enums.dart';

/// A single node in the personal memory graph — a person, place, event,
/// preference, story, etc. Stored as a plain `Map<String,dynamic>` in Hive
/// (no TypeAdapters, matching the app's convention) with the standard sync
/// fields. [GraphNode] is a thin typed view over that map.
class GraphNode {
  final String id;
  final GraphNodeType type;

  /// Display label — a name ("Arun"), place ("Chennai"), event ("Pongal 2025").
  final String label;

  /// Optional one-line descriptor shown under the label ("Eldest son").
  final String subtitle;

  /// Free-form structured attributes (e.g. {relationship: son, likes: drawing}).
  final Map<String, dynamic> attributes;

  /// Ids of MemoryItem records / photo paths tied to this node.
  final List<String> mediaRefs;

  final MemoryConfidence confidence;

  /// Where this node came from: 'user', 'caregiver', 'family', 'inferred'.
  final String source;

  const GraphNode({
    required this.id,
    required this.type,
    required this.label,
    this.subtitle = '',
    this.attributes = const {},
    this.mediaRefs = const [],
    this.confidence = MemoryConfidence.confirmed,
    this.source = 'user',
  });

  bool get isConfirmed => confidence == MemoryConfidence.confirmed;

  GraphNode copyWith({
    String? label,
    String? subtitle,
    Map<String, dynamic>? attributes,
    List<String>? mediaRefs,
    MemoryConfidence? confidence,
    String? source,
  }) {
    return GraphNode(
      id: id,
      type: type,
      label: label ?? this.label,
      subtitle: subtitle ?? this.subtitle,
      attributes: attributes ?? this.attributes,
      mediaRefs: mediaRefs ?? this.mediaRefs,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap({String? patientId}) => {
        kId: id,
        if (patientId != null) kPatientId: patientId,
        'type': type.id,
        'label': label,
        'subtitle': subtitle,
        'attributes': attributes,
        'mediaRefs': mediaRefs,
        'confidence': confidence.id,
        'source': source,
      };

  factory GraphNode.fromMap(Map<String, dynamic> m) => GraphNode(
        id: m[kId]?.toString() ?? '',
        type: GraphNodeTypeX.from(m['type'] as String?),
        label: m['label']?.toString() ?? '',
        subtitle: m['subtitle']?.toString() ?? '',
        attributes: (m['attributes'] as Map?)?.cast<String, dynamic>() ?? {},
        mediaRefs: (m['mediaRefs'] as List?)?.map((e) => e.toString()).toList() ?? [],
        confidence: MemoryConfidenceX.from(m['confidence'] as String?),
        source: m['source']?.toString() ?? 'user',
      );
}
