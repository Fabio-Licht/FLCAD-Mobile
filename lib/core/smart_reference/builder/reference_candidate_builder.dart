import '../../engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../canonical/canonical_reference_solver.dart';
import '../models/smart_reference_models.dart';
import '../ranking/reference_ranking_engine.dart';

class ReferenceCandidateBuilder {
  const ReferenceCandidateBuilder({
    required this.ranking,
    this.canonical = const CanonicalReferenceSolver(),
  });
  final ReferenceRankingEngine ranking;
  final CanonicalReferenceSolver canonical;
  List<ReferenceCandidateType> get supportedTypes =>
      ReferenceCandidateType.values;
  List<ReferenceCandidate> build(
    String sessionId,
    EngineeringFeatureSession source,
  ) {
    final candidates = <ReferenceCandidate>[];
    for (final feature in source.hypotheses) {
      final types = _types(feature);
      for (final type in types) {
        final primitiveIds =
            feature.evidence.expand((e) => e.primitiveIds).toSet().toList()
              ..sort();
        final relationships =
            feature.graph.edges.map((e) => e.relationship.name).toSet().toList()
              ..sort();
        final evidence = [
          for (final item in feature.evidence)
            ReferenceEvidence(
              id: '$sessionId:${feature.id}:${type.name}:${item.id}',
              source: item.source,
              description: item.description,
              primitiveIds: item.primitiveIds,
              featureIds: [feature.id],
              score: item.score,
            ),
        ];
        final discarded =
            ReferenceCandidateType.values
                .where((e) => categoryOf(e) == categoryOf(type) && e != type)
                .map((e) => e.name)
                .toList()
              ..sort();
        candidates.add(
          ReferenceCandidate(
            id: '$sessionId:${feature.id}:${type.name}',
            type: type,
            scores: ranking.calculate(feature),
            evidence: evidence,
            justification:
                '${type.name} suggested from feature ${feature.type.name}, primitives $primitiveIds and relationships $relationships.',
            primitiveIds: primitiveIds,
            featureIds: [feature.id],
            topologicalRelationships: relationships,
            discardedHypotheses: discarded,
            canonical: canonical.solve(type, feature),
          ),
        );
      }
    }
    return ranking.rank(candidates);
  }

  List<ReferenceCandidateType> _types(EngineeringFeatureHypothesis feature) =>
      switch (feature.type) {
        EngineeringFeatureType.datumFeature => const [
          ReferenceCandidateType.datumPlane,
          ReferenceCandidateType.basePlane,
        ],
        EngineeringFeatureType.flange => const [
          ReferenceCandidateType.supportPlane,
          ReferenceCandidateType.mainAxis,
          ReferenceCandidateType.mainCenter,
        ],
        EngineeringFeatureType.bearingSeat ||
        EngineeringFeatureType.shaft ||
        EngineeringFeatureType.revolution => const [
          ReferenceCandidateType.mainAxis,
          ReferenceCandidateType.revolutionAxis,
          ReferenceCandidateType.functionalCenter,
        ],
        EngineeringFeatureType.simpleHole ||
        EngineeringFeatureType.throughHole ||
        EngineeringFeatureType.blindHole ||
        EngineeringFeatureType.steppedHole ||
        EngineeringFeatureType.countersunkHole ||
        EngineeringFeatureType.threadedHole => const [
          ReferenceCandidateType.functionalAxis,
          ReferenceCandidateType.geometricCenter,
        ],
        EngineeringFeatureType.machiningFeature => const [
          ReferenceCandidateType.manufacturingPlane,
          ReferenceCandidateType.machiningSystem,
        ],
        EngineeringFeatureType.moldPartingCandidate => const [
          ReferenceCandidateType.symmetryPlane,
          ReferenceCandidateType.functionalSystem,
        ],
        _ => const [
          ReferenceCandidateType.functionalPlane,
          ReferenceCandidateType.localSystem,
        ],
      };
}
