import '../models/intelligence_models.dart';

class EngineeringScoreEngine {
  const EngineeringScoreEngine();
  EngineeringScore calculate(ProjectKnowledgeSnapshot s) {
    double bounded(double value) => value.clamp(0, 100).toDouble();
    final model = bounded(
          (s.averageFeatureQuality + s.averageValidationQuality) / 2,
        ),
        manufacturing = bounded(100 - s.criticalRegions.length * 4),
        maintainability = bounded(100 - s.dependencyRisks * 5),
        editability = bounded(100 - s.dependencyRisks * 3),
        health = bounded(
          (model +
                  s.averageReferenceQuality +
                  s.averageAlignmentQuality +
                  maintainability) /
              4,
        ),
        values = [
          model,
          s.averageFeatureQuality,
          s.averageReferenceQuality,
          s.averageAlignmentQuality,
          s.averageValidationQuality,
          manufacturing,
          maintainability,
          editability,
          health,
        ];
    return EngineeringScore(
      modelQuality: model,
      featureQuality: bounded(s.averageFeatureQuality),
      referenceQuality: bounded(s.averageReferenceQuality),
      alignmentQuality: bounded(s.averageAlignmentQuality),
      validationQuality: bounded(s.averageValidationQuality),
      manufacturability: manufacturing,
      maintainability: maintainability,
      editability: editability,
      projectHealth: health,
      overall: values.reduce((a, b) => a + b) / values.length,
    );
  }
}
