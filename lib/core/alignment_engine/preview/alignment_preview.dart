import '../models/alignment_models.dart';

class AlignmentPreview {
  const AlignmentPreview({
    required this.alignmentId,
    required this.translation,
    required this.rotation,
    required this.matrix,
    required this.rmsError,
    required this.maximumError,
    required this.averageError,
    required this.confidence,
    required this.estimatedQuality,
    required this.degreesOfFreedom,
    required this.lockedAxes,
  });
  final String alignmentId;
  final AlignmentVector translation, rotation;
  final AlignmentMatrix matrix;
  final double rmsError,
      maximumError,
      averageError,
      confidence,
      estimatedQuality;
  final int degreesOfFreedom;
  final Set<String> lockedAxes;
}

class AlignmentPreviewEngine {
  const AlignmentPreviewEngine();
  AlignmentPreview create(Alignment alignment) {
    final referenceCount =
            alignment.input.movingReferences.length +
            alignment.input.fixedReferences.length,
        rms = referenceCount == 0 ? 1.0 : 1 / referenceCount,
        max = rms * 1.8,
        avg = rms * .75,
        confidence = (1 - rms / 2).clamp(0, 1).toDouble(),
        quality = (confidence * 100).clamp(0, 100).toDouble();
    return AlignmentPreview(
      alignmentId: alignment.id,
      translation: alignment.parameters.translation,
      rotation: alignment.parameters.rotation,
      matrix: alignment.parameters.matrix,
      rmsError: rms,
      maximumError: max,
      averageError: avg,
      confidence: confidence,
      estimatedQuality: quality,
      degreesOfFreedom: 6 - alignment.parameters.lockedAxes.length.clamp(0, 6),
      lockedAxes: Set.unmodifiable(alignment.parameters.lockedAxes),
    );
  }
}
