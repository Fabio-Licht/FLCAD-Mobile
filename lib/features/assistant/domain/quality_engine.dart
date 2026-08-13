import '../models/quality_summary.dart';

class QualityEngine {
  const QualityEngine();
  QualitySummary calculate({
    required double photoQuality,
    required double coverage,
    required double scale,
    required double reconstruction,
    required double mesh,
    required double confidence,
  }) => QualitySummary(
    photoQuality: photoQuality.clamp(0, 100),
    coverage: coverage.clamp(0, 100),
    scale: scale.clamp(0, 100),
    reconstruction: reconstruction.clamp(0, 100),
    mesh: mesh.clamp(0, 100),
    confidence: confidence.clamp(0, 1),
  );
}
