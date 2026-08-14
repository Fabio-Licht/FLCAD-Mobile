import '../models/alignment_models.dart';
import '../preview/alignment_preview.dart';

class AlignmentQuality {
  const AlignmentQuality({
    required this.rms,
    required this.maximumError,
    required this.averageError,
    required this.stability,
    required this.referenceQuality,
    required this.transformationStability,
    required this.expectedRepeatability,
    required this.overall,
  });
  final double rms,
      maximumError,
      averageError,
      stability,
      referenceQuality,
      transformationStability,
      expectedRepeatability,
      overall;
}

class AlignmentQualityEngine {
  const AlignmentQualityEngine();
  AlignmentQuality evaluate(Alignment alignment, AlignmentPreview preview) {
    double score(double error) => (100 - error * 100).clamp(0, 100).toDouble();
    final rms = score(preview.rmsError),
        max = score(preview.maximumError),
        avg = score(preview.averageError),
        stability = alignment.parameters.matrix.valid ? 100.0 : 0.0,
        references = (alignment.input.movingReferences.length * 20)
            .clamp(0, 100)
            .toDouble(),
        transform = alignment.parameters.matrix.determinant3.abs() > 1e-12
            ? 100.0
            : 0.0,
        repeatability = preview.confidence * 100,
        values = [
          rms,
          max,
          avg,
          stability,
          references,
          transform,
          repeatability,
        ];
    return AlignmentQuality(
      rms: rms,
      maximumError: max,
      averageError: avg,
      stability: stability,
      referenceQuality: references,
      transformationStability: transform,
      expectedRepeatability: repeatability,
      overall: values.reduce((a, b) => a + b) / values.length,
    );
  }
}
