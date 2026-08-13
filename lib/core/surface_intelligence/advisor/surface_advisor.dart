import '../models/surface_models.dart';

class SurfaceExplanation {
  const SurfaceExplanation(
    this.candidateId,
    this.answer,
    this.evidenceIds,
    this.discardedAlternatives,
  );
  final String candidateId, answer;
  final List<String> evidenceIds, discardedAlternatives;
}

class SurfaceIntelligenceAdvisor {
  const SurfaceIntelligenceAdvisor();
  SurfaceExplanation explain(
    SurfaceCandidate candidate,
    List<SurfaceCandidate> alternatives,
  ) {
    final discarded = alternatives
        .where(
          (e) =>
              e.id != candidate.id &&
              e.regionIds.any(candidate.regionIds.contains),
        )
        .map((e) => e.kind.name)
        .toList();
    final reason = switch (candidate.classification) {
      SurfaceClassification.analytical =>
        'Analytical evidence provides the most robust and maintainable representation.',
      SurfaceClassification.transition =>
        'Boundary and continuity evidence requires a transition surface.',
      SurfaceClassification.freeform =>
        'Analytical hypotheses do not cover the observed curvature.',
      SurfaceClassification.hybrid =>
        'The region combines analytical evidence with unresolved freeform boundaries.',
    };
    return SurfaceExplanation(
      candidate.id,
      '$reason ${candidate.justification}',
      candidate.evidence.map((e) => e.id).toList(),
      discarded,
    );
  }
}
