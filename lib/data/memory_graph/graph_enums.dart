// ===============================================================
// MEMORY GRAPH — node types & confidence
// The backbone of Smirithi Saathi: the user's life stored as
// interconnected nodes (people, places, events…) rather than
// isolated text entries. Everything Saathi "knows" grounds here.
// ===============================================================

/// The kind of thing a node represents.
enum GraphNodeType {
  person,
  place,
  event,
  preference, // food, music, hobby…
  object,
  story,
  photo,
  routine,
}

extension GraphNodeTypeX on GraphNodeType {
  String get id => name;
  static GraphNodeType from(String? v) => GraphNodeType.values.firstWhere(
        (t) => t.name == v,
        orElse: () => GraphNodeType.object,
      );
}

/// How sure the system is about a fact — the spec's memory-safety rule
/// (§28): never turn an assumption into a confirmed personal fact.
enum MemoryConfidence {
  /// The user or caregiver confirmed it. Saathi may state it plainly.
  confirmed,

  /// The AI inferred it. Saathi must hedge ("I think this may be…").
  inferred,

  /// Not known. Saathi should say so, not guess.
  unknown,
}

extension MemoryConfidenceX on MemoryConfidence {
  String get id => name;
  static MemoryConfidence from(String? v) => MemoryConfidence.values.firstWhere(
        (c) => c.name == v,
        orElse: () => MemoryConfidence.inferred,
      );
}
