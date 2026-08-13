import '../../engineering_knowledge/models/knowledge_models.dart';
import '../../engineering_knowledge/reasoning/engineering_reasoner.dart';
import '../models/cognition_models.dart';

class AutomaticFeatureRecognizer {
  const AutomaticFeatureRecognizer(this.reasoner);
  final EngineeringReasoner reasoner;
  List<RecognizedFeature> recognize(
    List<PrimitiveRecognition> primitives, {
    Map<String, dynamic> facts = const {},
  }) {
    final result = <RecognizedFeature>[];
    for (var i = 0; i < primitives.length; i++) {
      final p = primitives[i],
          candidates = _candidates(p.kind, facts),
          caseData = reasoner.reason(reasonerCase(p, facts));
      for (final candidate in candidates) {
        final knowledge = caseData.best('feature.$candidate'),
            knowledgeConfidence = knowledge?.confidence ?? .35,
            confidence = (p.confidence * .65 + knowledgeConfidence * .35)
                .clamp(0, 1)
                .toDouble();
        if (confidence < .35) continue;
        result.add(
          RecognizedFeature(
            id: 'feature:${p.regionId}:$candidate',
            kind: candidate,
            confidence: confidence,
            evidence: p.evidence,
            provenance: '${p.provenance}; Engineering DNA 0.7',
            regionIds: [p.regionId],
            relatedFeatureIds: const [],
            knowledgeRuleIds: knowledge?.ruleIds ?? const [],
            explanation:
                'Recognized $candidate from ${p.kind} geometry at ${(p.confidence * 100).toStringAsFixed(1)}% and Engineering DNA support at ${(knowledgeConfidence * 100).toStringAsFixed(1)}%.',
            discardedAlternatives: candidates
                .where((c) => c != candidate)
                .toList(),
          ),
        );
      }
    }
    final linked = result.map((feature) {
      final related = result
          .where(
            (other) =>
                other.id != feature.id &&
                other.regionIds.any(feature.regionIds.contains),
          )
          .map((other) => other.id)
          .toList();
      return RecognizedFeature(
        id: feature.id,
        kind: feature.kind,
        confidence: feature.confidence,
        evidence: feature.evidence,
        provenance: feature.provenance,
        regionIds: feature.regionIds,
        relatedFeatureIds: related,
        knowledgeRuleIds: feature.knowledgeRuleIds,
        explanation: feature.explanation,
        discardedAlternatives: feature.discardedAlternatives,
      );
    }).toList();
    return linked..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  List<String> _candidates(String primitive, Map<String, dynamic> facts) =>
      switch (primitive) {
        'cylinder' =>
          facts['feature.thread'] == true
              ? ['thread', 'hole', 'boss', 'seat']
              : ['hole', 'boss', 'seat', 'recess'],
        'plane' => ['pocket', 'flange', 'guide', 'reinforcement'],
        'cone' => ['chamfer', 'recess'],
        'torus' => ['fillet', 'sealSeat'],
        'sphere' => ['seat', 'boss'],
        'revolution' => ['seat', 'housing'],
        'loft' || 'sweep' || 'patch' => ['rib', 'guide', 'reinforcement'],
        _ => ['feature'],
      };
  EngineeringCase reasonerCase(
    PrimitiveRecognition p,
    Map<String, dynamic> facts,
  ) => EngineeringCase(
    projectId: 'cognition',
    entityId: p.regionId,
    facts: facts,
    probabilities: {'surface.${p.kind}': p.confidence},
  );
}
