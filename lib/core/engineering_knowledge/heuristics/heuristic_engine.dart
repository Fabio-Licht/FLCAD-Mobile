import '../models/knowledge_models.dart';

class EngineeringHeuristic {
  const EngineeringHeuristic(this.id, this.description, this.evaluate);
  final String id, description;
  final KnowledgeInference? Function(EngineeringCase) evaluate;
}

class HeuristicEngine {
  HeuristicEngine([Iterable<EngineeringHeuristic>? heuristics])
    : heuristics = List.unmodifiable(heuristics ?? foundation());
  final List<EngineeringHeuristic> heuristics;
  List<KnowledgeInference> apply(EngineeringCase value) => heuristics
      .map((h) => h.evaluate(value))
      .whereType<KnowledgeInference>()
      .toList();
  static List<EngineeringHeuristic> foundation() => [
    EngineeringHeuristic(
      'heuristic.flangeSearch',
      'Symmetric hole arrangements should trigger a flange search',
      (c) {
        final count = (c.facts['hole.count'] as num?)?.toInt() ?? 0,
            symmetric = c.facts['symmetry.planar'] == true;
        if (count < 4 || !symmetric) return null;
        return const KnowledgeInference(
          conclusion: 'search.feature.flange',
          confidence: .8,
          explanation: 'At least four holes and planar symmetry were observed.',
          evidence: [
            KnowledgeEvidence(
              'hole.count',
              'Repeated holes',
              1,
              'engineering.case',
            ),
            KnowledgeEvidence(
              'symmetry.planar',
              'Planar symmetry',
              1,
              'engineering.case',
            ),
          ],
          ruleIds: ['heuristic.flangeSearch'],
        );
      },
    ),
  ];
}
