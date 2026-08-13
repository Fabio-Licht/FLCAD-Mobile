import '../models/sketch.dart';

class RecognizedSketchFeature {
  const RecognizedSketchFeature(this.kind, this.entityIds, this.confidence);
  final String kind;
  final List<String> entityIds;
  final double confidence;
}

abstract interface class SketchRecognizer {
  Future<List<RecognizedSketchFeature>> recognize(IntelligentSketch sketch);
}

class AlphaSketchRecognizer implements SketchRecognizer {
  const AlphaSketchRecognizer();
  @override
  Future<List<RecognizedSketchFeature>> recognize(
    IntelligentSketch sketch,
  ) async {
    final result = <RecognizedSketchFeature>[];
    for (final entity in sketch.entities) {
      if (entity.kind.name == 'circle') {
        result.add(RecognizedSketchFeature('hole-or-boss', [entity.id], .65));
      }
      if (entity.kind.name == 'slot') {
        result.add(RecognizedSketchFeature('slot', [entity.id], .9));
      }
    }
    return result;
  }
}
