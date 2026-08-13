import '../../reverse_intelligence/models/intelligence_models.dart';
import '../heuristics/heuristic_engine.dart';
import '../models/knowledge_models.dart';
import '../patterns/pattern_library.dart';
import '../probability/knowledge_probability.dart';
import '../rules/engineering_rules.dart';

class EngineeringReasoningResult {
  const EngineeringReasoningResult(
    this.caseData,
    this.inferences,
    this.explanation,
  );
  final EngineeringCase caseData;
  final List<KnowledgeInference> inferences;
  final String explanation;
  KnowledgeInference? best(String conclusion) {
    final values = inferences.where((i) => i.conclusion == conclusion).toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return values.isEmpty ? null : values.first;
  }
}

class EngineeringReasoner {
  EngineeringReasoner({
    EngineeringRulesEngine? rules,
    EngineeringPatternLibrary? patterns,
    HeuristicEngine? heuristics,
  }) : rules = rules ?? CoreEngineeringRules.create(),
       patterns = patterns ?? EngineeringPatternLibrary.foundation(),
       heuristics = heuristics ?? HeuristicEngine();
  final EngineeringRulesEngine rules;
  final EngineeringPatternLibrary patterns;
  final HeuristicEngine heuristics;
  final probability = const KnowledgeProbabilityEngine();
  EngineeringReasoningResult reason(EngineeringCase c) {
    final raw = [
          ...rules.infer(c),
          ...patterns.match(c),
          ...heuristics.apply(c),
        ],
        grouped = <String, List<KnowledgeInference>>{};
    for (final inference in raw) {
      (grouped[inference.conclusion] ??= []).add(inference);
    }
    final combined =
        grouped.entries
            .map(
              (e) => e.value.length == 1
                  ? e.value.single
                  : probability.combine(e.key, e.value),
            )
            .toList()
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final explanation = combined.isEmpty
        ? 'No engineering conclusion satisfied the available evidence.'
        : combined
              .map(
                (i) =>
                    '${i.conclusion}: ${(i.confidence * 100).toStringAsFixed(1)}% — ${i.explanation}',
              )
              .join('\n');
    return EngineeringReasoningResult(
      c,
      List.unmodifiable(combined),
      explanation,
    );
  }

  EngineeringCase fromArei(
    ReasoningSnapshot snapshot, {
    Map<String, dynamic> observedFacts = const {},
  }) {
    final probabilities = <String, double>{};
    for (final value in snapshot.classifications) {
      probabilities['part.${value.label}'] = value.probability;
    }
    for (final value in snapshot.manufacturing) {
      probabilities['process.${_process(value.label)}'] = value.probability;
    }
    final facts = <String, dynamic>{
      'mesh.watertight': snapshot.observation.isWatertight,
      'mesh.boundaryEdges': snapshot.observation.boundaryEdgeCount,
      ...observedFacts,
    };
    return EngineeringCase(
      projectId: snapshot.projectId,
      entityId: snapshot.meshId,
      facts: facts,
      probabilities: probabilities,
    );
  }

  String _process(String value) => switch (value) {
    'cncMachining' => 'cnc',
    'injectionMolding' => 'injection',
    'additiveManufacturing' => 'additive',
    _ => value,
  };
}
