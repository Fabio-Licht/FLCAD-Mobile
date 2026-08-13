import '../models/cognition_models.dart';

class SurfaceSuggestionEngine {
  const SurfaceSuggestionEngine();
  List<CognitionSuggestion> suggest(List<PrimitiveRecognition> primitives) {
    return primitives.map((p) {
      final recommendation = switch (p.kind) {
        'plane' => 'plane',
        'cylinder' || 'cone' || 'sphere' || 'torus' => 'revolution',
        'loft' => 'loft',
        'sweep' => 'sweep',
        'patch' => 'patchOrNurbs',
        _ => 'nurbsReview',
      };
      return CognitionSuggestion(
        'surface:${p.regionId}:$recommendation',
        SuggestionKind.surface,
        recommendation,
        0,
        p.confidence,
        '${p.kind} primitive evidence supports $recommendation representation; final fitting is outside cognition.',
        [p.regionId],
      );
    }).toList()..sort((a, b) => b.confidence.compareTo(a.confidence));
  }
}
