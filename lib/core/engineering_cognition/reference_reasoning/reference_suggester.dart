import '../models/cognition_models.dart';

class ReferenceSuggestionEngine {
  const ReferenceSuggestionEngine();
  List<CognitionSuggestion> suggest(
    List<PrimitiveRecognition> primitives,
    List<RecognizedFeature> features,
  ) {
    final result = <CognitionSuggestion>[];
    final planes = primitives.where((p) => p.kind == 'plane').toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    for (var i = 0; i < planes.take(3).length; i++) {
      final names = ['basePlane', 'secondaryPlane', 'tertiaryPlane'];
      result.add(
        CognitionSuggestion(
          'reference:${names[i]}',
          SuggestionKind.reference,
          names[i],
          i + 1,
          planes[i].confidence,
          'Stable planar region ranked by observed confidence.',
          [planes[i].regionId],
        ),
      );
    }
    final axial =
        primitives
            .where((p) => p.kind == 'cylinder' || p.kind == 'revolution')
            .toList()
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
    if (axial.isNotEmpty) {
      result.add(
        CognitionSuggestion(
          'reference:mainAxis',
          SuggestionKind.reference,
          'mainAxis',
          result.length + 1,
          axial.first.confidence,
          'Axial primitive supports a principal axis reference.',
          [axial.first.regionId],
        ),
      );
    }
    if (result.length >= 2) {
      result.add(
        CognitionSuggestion(
          'reference:origin',
          SuggestionKind.reference,
          'origin',
          result.length + 1,
          result
              .take(2)
              .map((v) => v.confidence)
              .reduce((a, b) => a < b ? a : b),
          'Intersection of the highest-confidence independent references.',
          result.take(2).map((v) => v.id).toList(),
        ),
      );
    }
    if (result.length >= 3) {
      result.add(
        CognitionSuggestion(
          'reference:coordinateSystem',
          SuggestionKind.reference,
          'coordinateSystem',
          result.length + 1,
          result
              .take(3)
              .map((v) => v.confidence)
              .reduce((a, b) => a < b ? a : b),
          'Three independent references can define a coordinate system.',
          result.take(3).map((v) => v.id).toList(),
        ),
      );
    }
    return result;
  }
}
