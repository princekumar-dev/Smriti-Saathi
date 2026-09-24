import 'dart:math';

import '../data/memory_graph/graph_enums.dart';
import '../data/memory_graph/graph_node.dart';
import 'memory_graph_service.dart';

/// The kind of personalised question — each is generated from the user's own
/// memory graph, never generic trivia (§14–15).
enum GameQuestionKind { whoIsThis, relationOf, whoWasWith, whereWasThis }

/// One gentle, personalised question.
class GameQuestion {
  final GameQuestionKind kind;
  final String prompt;

  /// On-device image path to show (a face, a place, a photo), if any.
  final String? imageRef;

  /// Answer choices; [correctIndex] is the right one.
  final List<String> options;
  final int correctIndex;

  /// The graph node the question is about (for follow-up / storytelling).
  final String subjectNodeId;

  const GameQuestion({
    required this.kind,
    required this.prompt,
    this.imageRef,
    required this.options,
    required this.correctIndex,
    required this.subjectNodeId,
  });

  String get correctAnswer => options[correctIndex];
}

/// Builds personalised memory games from [MemoryGraphService]. Difficulty is
/// gentle by design: 3 options, no timer, and it simply produces fewer
/// questions when the graph is still small (§14 "do not make it stressful").
class MemoryGameEngine {
  MemoryGameEngine._();
  static final MemoryGameEngine instance = MemoryGameEngine._();
  factory MemoryGameEngine() => instance;

  final MemoryGraphService _graph = MemoryGraphService();
  final Random _rng = Random();

  String? _imageOf(GraphNode n) {
    for (final ref in n.mediaRefs) {
      if (ref.isEmpty || ref.startsWith('http') || ref.startsWith('assets/')) {
        continue;
      }
      if (ref.contains('/') || ref.contains(r'\')) return ref;
    }
    return null;
  }

  /// Picks [count] distinct distractor labels from [pool], excluding [answer].
  List<String> _distractors(List<String> pool, String answer, int count) {
    final options = pool.where((p) => p != answer && p.trim().isNotEmpty).toList()
      ..shuffle(_rng);
    return options.take(count).toList();
  }

  GameQuestion _shuffleInto(String prompt, String? image, String answer,
      List<String> distractors, GameQuestionKind kind, String nodeId) {
    final opts = [answer, ...distractors]..shuffle(_rng);
    return GameQuestion(
      kind: kind,
      prompt: prompt,
      imageRef: image,
      options: opts,
      correctIndex: opts.indexOf(answer),
      subjectNodeId: nodeId,
    );
  }

  /// True when there's enough in the graph to build at least a short round.
  bool get hasEnoughContent {
    final people = _graph.nodesOfType(GraphNodeType.person);
    return people.length >= 3;
  }

  /// Generates up to [count] questions of the requested [kind] (or a gentle
  /// mix when [kind] is null). Returns fewer if the graph is sparse.
  List<GameQuestion> generate({GameQuestionKind? kind, int count = 5}) {
    final questions = <GameQuestion>[];

    // Try many times; skip nulls (a builder returns null when it can't build).
    for (var attempt = 0; attempt < count * 6 && questions.length < count; attempt++) {
      final GameQuestion? q = switch (kind) {
        GameQuestionKind.whoIsThis => _whoIsThis(),
        GameQuestionKind.relationOf => _relationOf(),
        GameQuestionKind.whoWasWith => _whoWasWith(),
        GameQuestionKind.whereWasThis => _whereWasThis(),
        null => _anyKind(),
      };
      if (q == null) continue;
      // Avoid asking about the same subject twice in a row.
      if (questions.any((e) => e.subjectNodeId == q.subjectNodeId && e.kind == q.kind)) {
        continue;
      }
      questions.add(q);
    }
    return questions;
  }

  GameQuestion? _anyKind() {
    final options = <GameQuestion? Function()>[
      _whoIsThis,
      _relationOf,
      _whoWasWith,
      _whereWasThis,
    ]..shuffle(_rng);
    for (final b in options) {
      final q = b();
      if (q != null) return q;
    }
    return null;
  }

  // "Who is this?" — show a person (photo if we have one), pick their name.
  GameQuestion? _whoIsThis() {
    final people = _graph.nodesOfType(GraphNodeType.person)
        .where((p) => p.attributes['self'] != true)
        .toList();
    if (people.length < 3) return null;
    final subject = people[_rng.nextInt(people.length)];
    final names = people.map((p) => p.label).toList();
    final distractors = _distractors(names, subject.label, 2);
    if (distractors.length < 2) return null;
    final img = _imageOf(subject);
    final prompt = img != null ? 'Who is this?' : 'Who is ${subject.subtitle.isNotEmpty ? 'your ${subject.subtitle}' : 'this person'}?';
    return _shuffleInto(prompt, img, subject.label, distractors,
        GameQuestionKind.whoIsThis, subject.id);
  }

  // "Who is X to you?" — pick the relationship for a known person.
  GameQuestion? _relationOf() {
    final people = _graph.nodesOfType(GraphNodeType.person)
        .where((p) => p.attributes['self'] != true && p.subtitle.trim().isNotEmpty)
        .toList();
    if (people.length < 2) return null;
    final subject = people[_rng.nextInt(people.length)];
    final rels = people.map((p) => p.subtitle).toSet().toList();
    final distractors = _distractors(rels, subject.subtitle, 2);
    if (distractors.isEmpty) return null;
    return _shuffleInto('Who is ${subject.label} to you?', _imageOf(subject),
        subject.subtitle, distractors, GameQuestionKind.relationOf, subject.id);
  }

  // "Who was with you at X?" — an event/place connected to a person.
  GameQuestion? _whoWasWith() {
    final events = [
      ..._graph.nodesOfType(GraphNodeType.event),
      ..._graph.nodesOfType(GraphNodeType.place),
    ];
    events.shuffle(_rng);
    for (final ev in events) {
      final linkedPeople = _graph
          .neighbors(ev.id)
          .where((l) => l.node.type == GraphNodeType.person)
          .map((l) => l.node)
          .toList();
      if (linkedPeople.isEmpty) continue;
      final answer = linkedPeople.first.label;
      final allNames = _graph
          .nodesOfType(GraphNodeType.person)
          .map((p) => p.label)
          .toList();
      final distractors = _distractors(allNames, answer, 2);
      if (distractors.length < 2) continue;
      return _shuffleInto('Who was with you at ${ev.label}?', _imageOf(ev),
          answer, distractors, GameQuestionKind.whoWasWith, ev.id);
    }
    return null;
  }

  // "Where was this?" — a photo/event connected to a place.
  GameQuestion? _whereWasThis() {
    final places = _graph.nodesOfType(GraphNodeType.place);
    if (places.length < 3) return null;
    final candidates = [
      ..._graph.nodesOfType(GraphNodeType.event),
      ..._graph.nodesOfType(GraphNodeType.photo),
    ]..shuffle(_rng);
    for (final subject in candidates) {
      final linkedPlace = _graph
          .neighbors(subject.id)
          .where((l) => l.node.type == GraphNodeType.place)
          .map((l) => l.node)
          .toList();
      if (linkedPlace.isEmpty) continue;
      final answer = linkedPlace.first.label;
      final placeNames = places.map((p) => p.label).toList();
      final distractors = _distractors(placeNames, answer, 2);
      if (distractors.length < 2) continue;
      return _shuffleInto('Where was this — ${subject.label}?',
          _imageOf(subject), answer, distractors,
          GameQuestionKind.whereWasThis, subject.id);
    }
    return null;
  }
}
