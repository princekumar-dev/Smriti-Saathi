import 'package:flutter/foundation.dart';

import '../data/memory_graph/graph_enums.dart';
import '../data/memory_graph/graph_node.dart';
import 'memory_graph_service.dart';
import 'memory_service.dart';

/// Backfills the personal memory graph from data the app already has — the
/// existing [MemoryItem]s (and, later, family records) — so the Memory Garden
/// has content from day one instead of starting empty. Idempotent: nodes are
/// de-duplicated by label+type inside [MemoryGraphService], so re-seeding is
/// safe.
class MemoryGraphSeeder {
  MemoryGraphSeeder._();
  static final MemoryGraphSeeder instance = MemoryGraphSeeder._();
  factory MemoryGraphSeeder() => instance;

  final MemoryGraphService _graph = MemoryGraphService();

  /// The user's own root node ("You" / their name) that family and preferences
  /// connect to. Reuses an existing self node (any person flagged `self:true`)
  /// so re-seeding under a different display name never creates a duplicate.
  Future<GraphNode> ensureSelf(String displayName) async {
    for (final n in _graph.nodesOfType(GraphNodeType.person)) {
      if (n.attributes['self'] == true) return n;
    }
    return _graph.addNode(
      type: GraphNodeType.person,
      label: displayName.trim().isEmpty ? 'You' : displayName.trim(),
      subtitle: 'You',
      attributes: const {'self': true},
      source: 'user',
    );
  }

  /// Maps a Memories-screen category to a graph node type.
  GraphNodeType _typeForCategory(String category) {
    switch (category) {
      case 'People':
        return GraphNodeType.person;
      case 'Places':
        return GraphNodeType.place;
      case 'Objects':
        return GraphNodeType.object;
      case 'Moments':
      default:
        return GraphNodeType.event;
    }
  }

  /// Parses a tagged person string like "Arun (son)" into (name, relationship).
  (String, String) _parsePerson(String raw) {
    final open = raw.indexOf('(');
    if (open >= 0 && raw.contains(')')) {
      final name = raw.substring(0, open).trim();
      final rel = raw.substring(open + 1, raw.indexOf(')')).trim();
      return (name, rel);
    }
    return (raw.trim(), '');
  }

  /// Turns every stored memory into connected graph nodes/edges.
  /// Returns the number of memories processed.
  Future<int> seedFromMemories(
    List<MemoryItem> memories, {
    required String selfName,
  }) async {
    if (memories.isEmpty) return 0;
    final self = await ensureSelf(selfName);

    for (final m in memories) {
      await _seedMemory(m, self);
    }
    debugPrint('MemoryGraphSeeder: seeded from ${memories.length} memories '
        '→ ${_graph.nodeCount} nodes');
    return memories.length;
  }

  /// Seeds a single freshly-added memory into the graph (used by the photo
  /// memory loop and [MemoryService.addMemory] so the graph grows the moment a
  /// memory is captured — no need to reopen the Garden).
  Future<void> seedOne(MemoryItem memory, {String selfName = ''}) async {
    final self = await ensureSelf(selfName);
    await _seedMemory(memory, self);
  }

  /// Builds the nodes/edges for one memory, connected to [self]. Idempotent.
  Future<void> _seedMemory(MemoryItem m, GraphNode self) async {
    final type = _typeForCategory(m.category);
    // The memory itself becomes a node (photo/event/place/person/object),
    // carrying its media so the Garden can show the picture.
    final primary = await _graph.addNode(
      type: type,
      label: m.title.isEmpty ? m.event : m.title,
      subtitle: m.subtitle,
      attributes: {
        if (m.description.isNotEmpty) 'description': m.description,
        if (m.reminiscenceStory.isNotEmpty) 'story': m.reminiscenceStory,
        'memoryId': m.id,
      },
      source: 'user',
    );
    if (m.mediaPath != null && m.mediaPath!.isNotEmpty) {
      await _graph.attachMedia(primary.id, m.mediaPath!);
    }

    // Tagged people → person nodes, linked to the memory and to the user.
    for (final tag in m.taggedPersons) {
      if (tag.trim().isEmpty) continue;
      final (name, rel) = _parsePerson(tag);
      if (name.isEmpty) continue;
      final person = await _graph.ensurePerson(
        name,
        relationship: rel,
        selfNodeId: self.id,
      );
      if (person.id != primary.id) {
        await _graph.addEdge(
          fromId: primary.id,
          toId: person.id,
          relation: 'with',
        );
      }
    }

    // An event tag on a non-event memory → connect it to that event.
    if (m.event.isNotEmpty && type != GraphNodeType.event) {
      final event = await _graph.addNode(
        type: GraphNodeType.event,
        label: m.event,
      );
      await _graph.addEdge(
        fromId: primary.id,
        toId: event.id,
        relation: 'during',
        inverse: 'included',
      );
    }
  }
}
