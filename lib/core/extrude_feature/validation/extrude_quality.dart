import '../models/extrude_models.dart';
import 'extrude_validation.dart';

class ExtrudeQuality {
  const ExtrudeQuality(
    this.overall,
    this.feature,
    this.manufacturability,
    this.rebuildStability,
    this.dependency,
    this.parameterConsistency,
  );
  final int overall,
      feature,
      manufacturability,
      rebuildStability,
      dependency,
      parameterConsistency;
}

class ExtrudeQualityEvaluator {
  const ExtrudeQualityEvaluator();
  ExtrudeQuality evaluate(ExtrudeFeature f, ExtrudeValidationResult v) {
    final issues = v.issues.length,
        feature = (100 - issues * 12).clamp(0, 100),
        manufacturing =
            (100 -
                    (f.parameters.draftAngle.abs() > 15 ? 15 : 0) -
                    (f.parameters.distance > 1000 ? 20 : 0))
                .clamp(0, 100),
        stability = f.status == ExtrudeStatus.failed ? 50 : 100,
        dependency = (100 - f.dependencies.where((d) => d.isEmpty).length * 10)
            .clamp(0, 100),
        parameters = (100 - (f.parameters.distance <= 0 ? 30 : 0)).clamp(
          0,
          100,
        ),
        overall =
            ((feature + manufacturing + stability + dependency + parameters) /
                    5)
                .round();
    return ExtrudeQuality(
      overall,
      feature,
      manufacturing,
      stability,
      dependency,
      parameters,
    );
  }
}
