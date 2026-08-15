import '../models/engineering_feature_models.dart';

class EngineeringFeatureRecommendation {
  EngineeringFeatureRecommendation({
    required this.id,
    required this.hypothesisId,
    required this.why,
    required Iterable<FeatureEvidence> evidence,
    required Iterable<String> primitiveIds,
    required Iterable<FeatureGraphEdge> relationships,
    required this.scores,
    required Iterable<String> discardedHypotheses,
    required this.strategy,
  }) : evidence = List.unmodifiable(evidence),
       primitiveIds = List.unmodifiable(primitiveIds),
       relationships = List.unmodifiable(relationships),
       discardedHypotheses = List.unmodifiable(discardedHypotheses);
  final String id, hypothesisId, why;
  final List<FeatureEvidence> evidence;
  final List<String> primitiveIds, discardedHypotheses;
  final List<FeatureGraphEdge> relationships;
  final FeatureScores scores;
  final ReconstructionStrategy strategy;
  Map<String, dynamic> toJson() => {
    'id': id,
    'hypothesisId': hypothesisId,
    'why': why,
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'primitives': primitiveIds,
    'relationships': relationships.map((e) => e.toJson()).toList(),
    'scores': scores.toJson(),
    'discardedHypotheses': discardedHypotheses,
    'strategy': strategy.toJson(),
    'consultative': true,
    'commandsExecuted': false,
    'geometryModified': false,
  };
}

class EngineeringFeatureAdvisor {
  const EngineeringFeatureAdvisor();
  List<EngineeringFeatureRecommendation> advise(
    EngineeringFeatureSession session,
  ) => List.unmodifiable(
    session.hypotheses.map(
      (value) => EngineeringFeatureRecommendation(
        id: '${value.id}:recommendation',
        hypothesisId: value.id,
        why: value.justification,
        evidence: value.evidence,
        primitiveIds: value.evidence.expand((e) => e.primitiveIds).toSet(),
        relationships: value.graph.edges,
        scores: value.scores,
        discardedHypotheses: value.discardedHypotheses,
        strategy: value.strategy,
      ),
    ),
  );
}
