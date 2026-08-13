import '../../adaptive_surface/continuity/surface_continuity.dart';
import '../models/surface_models.dart';

class SurfaceContinuityEstimator {
  const SurfaceContinuityEstimator({this.tolerance = 1e-3});
  final double tolerance;
  ContinuityPrediction estimate({
    required double positionError,
    required double tangentError,
    required double curvatureError,
    required double derivativeError,
  }) {
    final level = positionError > tolerance
        ? SurfaceContinuityLevel.g0
        : tangentError > tolerance
        ? SurfaceContinuityLevel.g0
        : curvatureError > tolerance
        ? SurfaceContinuityLevel.g1
        : derivativeError > tolerance
        ? SurfaceContinuityLevel.g2
        : SurfaceContinuityLevel.g3;
    final worst = [
          positionError,
          tangentError,
          curvatureError,
          derivativeError,
        ].reduce((a, b) => a > b ? a : b),
        confidence = (1 - worst / (tolerance * 10)).clamp(0, 1).toDouble();
    return ContinuityPrediction(
      level,
      confidence,
      'Estimated ${level.name.toUpperCase()} from boundary, tangent, curvature and derivative evidence',
    );
  }
}
