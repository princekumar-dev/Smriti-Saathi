import 'package:flutter/foundation.dart';

import '../data/local/local_store.dart';
import '../data/repositories/synced_repository.dart';
import '../data/memory_graph/graph_enums.dart';
import '../data/memory_graph/graph_node.dart';
import '../data/memory_graph/graph_edge.dart';

/// ===============================================================
/// MEMORY GRAPH SERVICE
/// The single source of truth for the user's personal memory graph:
/// people, places, events, preferences and the relationships between
/// them. Offline-first (Hive, local-only boxes). Saathi, the Memory
/// Garden, personalised games and RAG all read through this.
/// ===============================================================
class MemoryGraphService extends ChangeNotifier {
  MemoryGraphService._();
  static final MemoryGraphService instance = MemoryGraphService._();
  factory MemoryGraphService() => instance;

  final SyncedRepository _nodes =
      SyncedRepository(LocalStore.boxGraphNodes, synced: false);
  final SyncedRepository _edges =
      SyncedRepository(LocalStore.boxGraphEdges, synced: false);

  String? _patientId;
  int _seq = 0;

  /// Scopes the graph to one patient (nodes/edges carry patientId).
  void bindPatient(String? patientId) {
    _patientId = patientId;
    notifyListeners();
  }

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_seq++}';

  // ── Reads ────────────────────────────────────────────────────

  List<GraphNode> get nodes => _nodes
      .getAll(patientId: _patientId)
      .map((m) => GraphNode.fromMap(m))
      .toList();

  List<GraphEdge> get edges => _edges
      .getAll(patientId: _patientId)
      .map((m) => GraphEdge.fromMap(m))
      .toList();

  List<GraphNode> nodesOfType(GraphNodeType type) =>
      nodes.where((n) => n.type == type).toList();

  GraphNode? nodeById(String id) {
    final m = _nodes.getById(id);
    return m == null ? null : GraphNode.fromMap(m);
  }

  /// Case-insensitive label lookup, optionally filtered by [type].
  GraphNode? findByLabel(String label, {GraphNodeType? type}) {
    final q = label.trim().toLowerCase();
    for (final n in nodes) {
      if (n.label.trim().toLowerCase() == q &&
          (type == null || n.type == type)) {
        return n;
      }
    }
    return null;
  }

  /// Every node directly connected to [nodeId], paired with the edge.
  List<({GraphEdge edge, GraphNode node, bool outgoing})> neighbors(
      String nodeId) {
    final result = <({GraphEdge edge, GraphNode node, bool outgoing})>[];
    for (final e in edges) {
      if (e.fromId == nodeId) {
        final other = nodeById(e.toId);
        if (other != null) {
          result.add((edge: e, node: other, outgoing: true));
        }
      } else if (e.toId == nodeId) {
        final other = nodeById(e.fromId);
        if (other != null) {
          result.add((edge: e, node: other, outgoing: false));
        }
      }
    }
    return result;
  }

  // ── Writes ───────────────────────────────────────────────────

  /// Adds a node (or returns the existing one with the same label+type).
  Future<GraphNode> addNode({
    required GraphNodeType type,
    required String label,
    String subtitle = '',
    Map<String, dynamic> attributes = const {},
    MemoryConfidence confidence = MemoryConfidence.confirmed,
    String source = 'user',
  }) async {
    final existing = findByLabel(label, type: type);
    if (existing != null) return existing;
    final node = GraphNode(
      id: _newId('node'),
      type: type,
      label: label.trim(),
      subtitle: subtitle,
      attributes: attributes,
      confidence: confidence,
      source: source,
    );
    await _nodes.upsert(node.toMap(patientId: _patientId));
    notifyListeners();
    return node;
  }

  Future<void> upsertNode(GraphNode node) async {
    await _nodes.upsert(node.toMap(patientId: _patientId));
    notifyListeners();
  }

  /// Marks a node's fact as user/caregiver-confirmed (§28 memory safety).
  Future<void> confirmNode(String id) async {
    final n = nodeById(id);
    if (n == null) return;
    await upsertNode(n.copyWith(confidence: MemoryConfidence.confirmed));
  }

  Future<void> deleteNode(String id) async {
    await _nodes.delete(id);
    for (final e in edges.where((e) => e.fromId == id || e.toId == id)) {
      await _edges.delete(e.id);
    }
    notifyListeners();
  }

  /// Links [nodeId] to a stored MemoryItem / photo path.
  Future<void> attachMedia(String nodeId, String mediaRef) async {
    final n = nodeById(nodeId);
    if (n == null || n.mediaRefs.contains(mediaRef)) return;
    await upsertNode(n.copyWith(mediaRefs: [...n.mediaRefs, mediaRef]));
  }

  /// Creates a relationship. If an equivalent edge exists, returns it.
  Future<GraphEdge> addEdge({
    required String fromId,
    required String toId,
    required String relation,
    String inverse = '',
    MemoryConfidence confidence = MemoryConfidence.confirmed,
    String source = 'user',
  }) async {
    final existing = edges.firstWhere(
      (e) =>
          e.fromId == fromId &&
          e.toId == toId &&
          e.relation.toLowerCase() == relation.toLowerCase(),
      orElse: () => const GraphEdge(id: '', fromId: '', toId: '', relation: ''),
    );
    if (existing.id.isNotEmpty) return existing;
    final edge = GraphEdge(
      id: _newId('edge'),
      fromId: fromId,
      toId: toId,
      relation: relation.trim(),
      inverse: inverse.trim(),
      confidence: confidence,
      source: source,
    );
    await _edges.upsert(edge.toMap(patientId: _patientId));
    notifyListeners();
    return edge;
  }

  /// Convenience: find-or-create a person and connect them to the user.
  Future<GraphNode> ensurePerson(String name,
      {String relationship = '', String selfNodeId = ''}) async {
    final person = await addNode(
      type: GraphNodeType.person,
      label: name,
      subtitle: relationship,
      attributes: relationship.isEmpty ? const {} : {'relationship': relationship},
    );
    if (selfNodeId.isNotEmpty && relationship.isNotEmpty) {
      await addEdge(fromId: selfNodeId, toId: person.id, relation: relationship);
    }
    return person;
  }

  /// A grounded, human-readable summary of [nodeId] and its connections —
  /// used by RAG/storytelling. Only states what's in the graph (§5, §28).
  String describe(String nodeId) {
    final n = nodeById(nodeId);
    if (n == null) return '';
    final b = StringBuffer(n.label);
    if (n.subtitle.isNotEmpty) b.write(' (${n.subtitle})');
    final near = neighbors(nodeId);
    for (final link in near) {
      final rel = link.outgoing ? link.edge.relation : link.edge.inverse;
      final label = rel.isEmpty ? 'connected to' : rel;
      b.write('; $label ${link.node.label}');
    }
    return b.toString();
  }

  /// True while the underlying store is open.
  bool get isReady => LocalStore().isReady;

  int get nodeCount => _nodes.getAll(patientId: _patientId).length;
}
