import '../models/reference_models.dart';
import '../validation/reference_validation.dart';

class ReferenceRecommendation {
  const ReferenceRecommendation({
    required this.title,
    required this.confidence,
    required this.explanation,
    required this.alternatives,
    required this.impact,
  });
  final String title, explanation, impact;
  final double confidence;
  final List<String> alternatives;
}

class ReferenceAdvisor {
  const ReferenceAdvisor();
  List<ReferenceRecommendation> analyze(
    ReferenceEntity entity,
    ReferenceValidationResult validation,
  ) => [
    ReferenceRecommendation(
      title: switch (entity.type) {
        ReferenceType.datumPlane ||
        ReferenceType.constructionPlane => 'Best plane strategy',
        ReferenceType.datumAxis ||
        ReferenceType.constructionAxis => 'Best axis strategy',
        ReferenceType.coordinateSystem ||
        ReferenceType.referenceFrame => 'Best coordinate system',
        _ => 'Best reference origin',
      },
      confidence: validation.valid ? .92 : .65,
      explanation: validation.valid
          ? 'The selected construction is stable'
          : 'Resolve diagnostics to improve reliability',
      alternatives: const ['Three points', 'Existing face', 'Imported system'],
      impact: validation.valid ? 'Alignment ready' : 'Downstream rebuild risk',
    ),
  ];
}
