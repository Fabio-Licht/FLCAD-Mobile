import '../models/transition_models.dart';
import 'transition_validation.dart';

class TransitionQuality {
  const TransitionQuality({
    required this.path,
    required this.guide,
    required this.loft,
    required this.sweep,
    required this.dependency,
    required this.manufacturability,
    required this.rebuildStability,
    required this.overall,
  });
  final double path,
      guide,
      loft,
      sweep,
      dependency,
      manufacturability,
      rebuildStability,
      overall;
}

class TransitionQualityEngine {
  const TransitionQualityEngine();
  TransitionQuality evaluate(
    TransitionFeature f,
    TransitionValidationResult validation,
  ) {
    double score(double penalty) =>
        (100 - validation.issues.length * penalty).clamp(0, 100).toDouble();
    final path = f.input.pathIds.isEmpty && f.family == TransitionFamily.sweep
            ? 0.0
            : score(12),
        guide = f.input.guideIds.isEmpty ? 80.0 : score(10),
        loft = f.family == TransitionFamily.loft ? score(9) : 100.0,
        sweep = f.family == TransitionFamily.sweep ? score(9) : 100.0,
        dependency = score(8),
        manufacturing = score(11),
        rebuild = f.status == TransitionStatus.failed ? 20.0 : score(7),
        values = <double>[];
    values.addAll([
      path,
      guide,
      loft,
      sweep,
      dependency,
      manufacturing,
      rebuild,
    ]);
    return TransitionQuality(
      path: path,
      guide: guide,
      loft: loft,
      sweep: sweep,
      dependency: dependency,
      manufacturability: manufacturing,
      rebuildStability: rebuild,
      overall: values.reduce((a, b) => a + b) / values.length,
    );
  }
}
