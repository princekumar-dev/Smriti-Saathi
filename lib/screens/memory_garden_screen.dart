import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/memory_graph/graph_enums.dart';
import '../data/memory_graph/graph_node.dart';
import '../services/memory_graph_seeder.dart';
import '../services/memory_graph_service.dart';
import '../services/memory_service.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/screen_header.dart';

/// ===============================================================
/// MEMORY GARDEN
/// A visual, emotionally warm view of the user's personal memory
/// graph — people, places, events, preferences and photos, and the
/// connections between them. Backed by [MemoryGraphService]; seeded
/// on first open from the user's existing memories.
/// ===============================================================
class MemoryGardenScreen extends StatefulWidget {
  const MemoryGardenScreen({super.key});

  @override
  State<MemoryGardenScreen> createState() => _MemoryGardenScreenState();
}

class _MemoryGardenScreenState extends State<MemoryGardenScreen> {
  final MemoryGraphService _graph = MemoryGraphService();
  GraphNodeType? _filter; // null = All
  bool _seeding = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = AuthScope.of(context);
    final patient = auth.activePatient;
    _graph.bindPatient(patient?.id);
    // Seed the graph from existing memories (idempotent — safe every open).
    await MemoryGraphSeeder().seedFromMemories(
      MemoryService().memories,
      selfName: patient?.name ?? 'You',
    );
    if (mounted) setState(() => _seeding = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _graph,
          builder: (context, _) {
            final nodes = _filter == null
                ? _graph.nodes
                : _graph.nodesOfType(_filter!);
            return Column(
              children: [
                const ScreenHeader(
                  title: 'Memory Garden',
                  subtitle: 'Your life, connected',
                  icon: Icons.spa_rounded,
                  showBack: true,
                ),
                _buildStats(),
                _buildFilters(),
                Expanded(child: _buildBody(nodes)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Summary strip: how much of the user's life is captured ──
  Widget _buildStats() {
    final people = _graph.nodesOfType(GraphNodeType.person).length;
    final places = _graph.nodesOfType(GraphNodeType.place).length;
    final events = _graph.nodesOfType(GraphNodeType.event).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.emeraldGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius28),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat('$people', 'People'),
          _statDivider(),
          _stat('$places', 'Places'),
          _statDivider(),
          _stat('$events', 'Events'),
          _statDivider(),
          _stat('${_graph.edges.length}', 'Links'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.comfortaa(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85))),
        ],
      );

  Widget _statDivider() => Container(
      width: 1, height: 34, color: Colors.white.withValues(alpha: 0.25));

  // ── Category filter chips ──
  Widget _buildFilters() {
    final types = <GraphNodeType?>[
      null,
      ...GraphNodeType.values.where((t) => _graph.nodesOfType(t).isNotEmpty),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = types[i];
          final selected = t == _filter;
          final label = t == null ? 'All' : _GardenVisual.of(t).plural;
          return AnimatedScaleButton(
            onTap: () => setState(() => _filter = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppTheme.forest : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: selected ? AppTheme.forest : AppTheme.divider,
                  width: 1.4,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppTheme.deepForest,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(List<GraphNode> nodes) {
    if (_seeding && nodes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (nodes.isEmpty) return _buildEmpty();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.92,
      ),
      itemCount: nodes.length,
      itemBuilder: (context, i) => _NodeCard(
        node: nodes[i],
        onTap: () => _showNodeDetail(nodes[i]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_rounded, size: 64, color: AppTheme.sage),
            const SizedBox(height: 16),
            Text('Your garden is just beginning',
                textAlign: TextAlign.center,
                style: GoogleFonts.comfortaa(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepForest)),
            const SizedBox(height: 8),
            Text(
              'Add memories and talk to Saathi — the people, places and '
              'moments you share will grow here, connected together.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14.5, color: AppTheme.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // ── Node detail: the node + its connections (the graph made tangible) ──
  void _showNodeDetail(GraphNode node) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NodeDetailSheet(
        node: node,
        graph: _graph,
        onOpenNode: (n) {
          Navigator.pop(context);
          _showNodeDetail(n);
        },
      ),
    );
  }
}

/// Icon + colour + labels for each node type, so the Garden reads at a glance.
class _GardenVisual {
  final IconData icon;
  final Color color;
  final Color soft;
  final String plural;

  const _GardenVisual(this.icon, this.color, this.soft, this.plural);

  static _GardenVisual of(GraphNodeType type) {
    switch (type) {
      case GraphNodeType.person:
        return const _GardenVisual(
            Icons.person_rounded, AppTheme.forest, AppTheme.paleSage, 'Family');
      case GraphNodeType.place:
        return const _GardenVisual(Icons.place_rounded, AppTheme.terracotta,
            AppTheme.paleTerracotta, 'Places');
      case GraphNodeType.event:
        return const _GardenVisual(Icons.celebration_rounded, AppTheme.coral,
            AppTheme.paleCoral, 'Events');
      case GraphNodeType.preference:
        return const _GardenVisual(Icons.favorite_rounded, AppTheme.warmAmber,
            Color(0xFFFDF3DD), 'Likes');
      case GraphNodeType.object:
        return const _GardenVisual(Icons.category_rounded, AppTheme.forest,
            AppTheme.paleSage, 'Objects');
      case GraphNodeType.story:
        return const _GardenVisual(Icons.auto_stories_rounded,
            AppTheme.lavender, Color(0xFFEDEAF6), 'Stories');
      case GraphNodeType.photo:
        return const _GardenVisual(Icons.photo_rounded, AppTheme.terracotta,
            AppTheme.paleTerracotta, 'Photos');
      case GraphNodeType.routine:
        return const _GardenVisual(Icons.schedule_rounded, AppTheme.forest,
            AppTheme.paleSage, 'Routines');
    }
  }
}

/// The first mediaRef that points at an on-device image file, or null.
String? _imageRefOf(GraphNode node) {
  for (final ref in node.mediaRefs) {
    if (ref.isEmpty || ref.startsWith('http') || ref.startsWith('assets/')) {
      continue;
    }
    if (ref.contains('/') || ref.contains(r'\')) return ref;
  }
  return null;
}

/// A single memory node in the grid.
class _NodeCard extends StatelessWidget {
  final GraphNode node;
  final VoidCallback onTap;

  const _NodeCard({required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = _GardenVisual.of(node.type);
    final img = _imageRefOf(node);
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radius28),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.divider, width: 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo or type avatar
            Expanded(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius18),
                  child: img != null
                      ? Image(
                          image: FileImage(File(img)),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatar(v),
                        )
                      : _avatar(v),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              node.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepForest),
            ),
            if (node.subtitle.isNotEmpty)
              Text(
                node.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: v.color, fontWeight: FontWeight.w600),
              ),
            if (!node.isConfirmed)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('Not confirmed yet',
                    style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.muted)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(_GardenVisual v) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: v.soft,
          borderRadius: BorderRadius.circular(AppTheme.radius18),
        ),
        child: Icon(v.icon, size: 46, color: v.color),
      );
}

/// Bottom sheet showing one node, its photo/story, and — the heart of the
/// graph — the other memories it connects to, each tappable.
class _NodeDetailSheet extends StatefulWidget {
  final GraphNode node;
  final MemoryGraphService graph;
  final ValueChanged<GraphNode> onOpenNode;

  const _NodeDetailSheet({
    required this.node,
    required this.graph,
    required this.onOpenNode,
  });

  @override
  State<_NodeDetailSheet> createState() => _NodeDetailSheetState();
}

class _NodeDetailSheetState extends State<_NodeDetailSheet> {
  late GraphNode _node = widget.node;

  @override
  Widget build(BuildContext context) {
    final v = _GardenVisual.of(_node.type);
    final img = _imageRefOf(_node);
    final links = widget.graph.neighbors(_node.id);
    final story = _node.attributes['story']?.toString() ?? '';
    final desc = _node.attributes['description']?.toString() ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: v.soft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(v.icon, color: v.color, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_node.label,
                          style: GoogleFonts.comfortaa(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepForest)),
                      if (_node.subtitle.isNotEmpty)
                        Text(_node.subtitle,
                            style: GoogleFonts.dmSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: v.color)),
                    ],
                  ),
                ),
              ],
            ),
            if (img != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radius18),
                child: Image(
                  image: FileImage(File(img)),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            if (story.isNotEmpty || desc.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(story.isNotEmpty ? story : desc,
                  style: GoogleFonts.dmSans(
                      fontSize: 15.5, height: 1.45, color: AppTheme.ink)),
            ],
            if (!_node.isConfirmed) ...[
              const SizedBox(height: 18),
              _buildConfirmBanner(),
            ],
            const SizedBox(height: 22),
            Text('Connected memories',
                style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.deepForest)),
            const SizedBox(height: 12),
            if (links.isEmpty)
              Text('No connections yet.',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: AppTheme.muted))
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: links.map((l) {
                  final rel =
                      l.outgoing ? l.edge.relation : l.edge.inverse;
                  return _ConnectionChip(
                    node: l.node,
                    relation: rel,
                    onTap: () => widget.onOpenNode(l.node),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3DD),
        borderRadius: BorderRadius.circular(AppTheme.radius18),
        border: Border.all(color: AppTheme.warmAmber, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Is this right?',
              style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepForest)),
          const SizedBox(height: 4),
          Text('Saathi guessed this. Confirm it so it can be trusted.',
              style: GoogleFonts.dmSans(
                  fontSize: 13.5, color: AppTheme.muted, height: 1.35)),
          const SizedBox(height: 12),
          AnimatedScaleButton(
            onTap: () async {
              await widget.graph.confirmNode(_node.id);
              final updated = widget.graph.nodeById(_node.id);
              if (updated != null && mounted) {
                setState(() => _node = updated);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppTheme.emeraldGradient,
                borderRadius: BorderRadius.circular(AppTheme.radius18),
              ),
              child: Text('Yes, that\'s right',
                  style: AppTheme.buttonText(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable chip showing "relation → connected node".
class _ConnectionChip extends StatelessWidget {
  final GraphNode node;
  final String relation;
  final VoidCallback onTap;

  const _ConnectionChip({
    required this.node,
    required this.relation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final v = _GardenVisual.of(node.type);
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: v.color.withValues(alpha: 0.4), width: 1.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(v.icon, size: 16, color: v.color),
            const SizedBox(width: 6),
            Text(
              relation.isEmpty ? node.label : '$relation · ${node.label}',
              style: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.deepForest),
            ),
          ],
        ),
      ),
    );
  }
}




