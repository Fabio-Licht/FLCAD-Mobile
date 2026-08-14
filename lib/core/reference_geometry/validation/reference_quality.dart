import '../models/reference_models.dart';
import 'reference_validation.dart';

class ReferenceQuality {
  const ReferenceQuality({
    required this.plane,
    required this.axis,
    required this.stability,
    required this.dependency,
    required this.alignmentReadiness,
    required this.overall,
  });
  final double plane, axis, stability, dependency, alignmentReadiness, overall;
}

class ReferenceQualityEngine {
  const ReferenceQualityEngine();
  ReferenceQuality evaluate(
    ReferenceEntity entity,
    ReferenceValidationResult validation,
  ) {
    final base = (100 - validation.issues.length * 18).clamp(0, 100).toDouble(),
        plane =
            {
              ReferenceType.datumPlane,
              ReferenceType.constructionPlane,
            }.contains(entity.type)
            ? base
            : 100.0,
        axis =
            {
              ReferenceType.datumAxis,
              ReferenceType.constructionAxis,
            }.contains(entity.type)
            ? base
            : 100.0,
        stability = entity.frozen ? 100.0 : base,
        dependency = (100 - entity.dependencies.length * 2)
            .clamp(0, 100)
            .toDouble(),
        alignment = entity.parameters.origin.finite ? base : 0.0,
        values = <double>[plane, axis, stability, dependency, alignment];
    return ReferenceQuality(
      plane: plane,
      axis: axis,
      stability: stability,
      dependency: dependency,
      alignmentReadiness: alignment,
      overall: values.reduce((a, b) => a + b) / values.length,
    );
  }
}
