import '../models/smart_reference_models.dart';

class ReferenceRecommendation {
  ReferenceRecommendation({
    required this.reference,
    required Iterable<AlignmentStrategy> strategies,
  }) : strategies = List.unmodifiable(strategies);
  final ReferenceCandidate reference;
  final List<AlignmentStrategy> strategies;
  Map<String, dynamic> toJson() => {
    'referenceId': reference.id,
    'why': reference.justification,
    'primitives': reference.primitiveIds,
    'features': reference.featureIds,
    'topologicalRelationships': reference.topologicalRelationships,
    'evidence': reference.evidence.map((e) => e.toJson()).toList(),
    'scores': reference.scores.toJson(),
    'discardedHypotheses': reference.discardedHypotheses,
    'strategies': strategies.map((e) => e.toJson()).toList(),
    'consultative': true,
    'commandsExecuted': false,
    'entitiesCreated': false,
    'geometryModified': false,
  };
}

class ReferenceStrategyAdvisor {
  const ReferenceStrategyAdvisor();
  List<ReferenceRecommendation> advise(SmartReferenceSession session) =>
      List.unmodifiable(
        session.candidates.map(
          (candidate) => ReferenceRecommendation(
            reference: candidate,
            strategies: session.strategies.where(
              (strategy) => strategy.steps.contains(candidate.id),
            ),
          ),
        ),
      );
}
