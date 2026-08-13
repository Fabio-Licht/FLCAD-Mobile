import '../models/cognition_models.dart';

class ReconstructionRecommendationEngine {
  const ReconstructionRecommendationEngine();
  List<CognitionSuggestion> recommend(
    List<CognitionSuggestion> references,
    List<CognitionSuggestion> surfaces,
    List<RecognizedFeature> features,
  ) {
    final result = <CognitionSuggestion>[];
    var order = 1;
    for (final r in references) {
      result.add(
        CognitionSuggestion(
          'reconstruction:${r.id}',
          SuggestionKind.reference,
          r.recommendation,
          order++,
          r.confidence,
          'References precede sketches, surfaces and features: ${r.reason}',
          r.sourceIds,
        ),
      );
    }
    for (final feature in features.where(
      (f) => [
        'hole',
        'pocket',
        'slot',
        'flange',
        'boss',
        'guide',
      ].contains(f.kind),
    )) {
      result.add(
        CognitionSuggestion(
          'reconstruction:sketch:${feature.id}',
          SuggestionKind.sketch,
          'sketchFor:${feature.kind}',
          order++,
          feature.confidence,
          'A parametric ${feature.kind} generally requires a defining sketch after references.',
          feature.regionIds,
        ),
      );
    }
    for (final surface in surfaces) {
      result.add(
        CognitionSuggestion(
          'reconstruction:${surface.id}',
          SuggestionKind.surface,
          surface.recommendation,
          order++,
          surface.confidence,
          'Surface representation follows its supporting references and sketches.',
          surface.sourceIds,
        ),
      );
    }
    for (final feature in features) {
      result.add(
        CognitionSuggestion(
          'reconstruction:feature:${feature.id}',
          SuggestionKind.feature,
          feature.kind,
          order++,
          feature.confidence,
          'Create or validate the feature only after its references and geometry are established.',
          feature.regionIds,
        ),
      );
    }
    return result;
  }
}
