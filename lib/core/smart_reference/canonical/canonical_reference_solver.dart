import '../../engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../models/smart_reference_models.dart';

class CanonicalReferenceSolver {
  const CanonicalReferenceSolver();
  CanonicalReferenceSuggestion solve(
    ReferenceCandidateType type,
    EngineeringFeatureHypothesis feature,
  ) => CanonicalReferenceSuggestion(
    measuredReference: feature.canonicalSuggestion.measuredFeature,
    canonicalReference: type.name,
    angularErrorDegrees: feature.canonicalSuggestion.deviation,
    confidence: feature.scores.overallConfidence,
    justification:
        'Canonical ${type.name} projected from ${feature.type.name}; no reference entity was created.',
    reasons: [
      'feature:${feature.id}',
      'canonicalFeature:${feature.canonicalSuggestion.canonicalFeature}',
      'graph:${feature.graph.id}',
    ],
  );
}
