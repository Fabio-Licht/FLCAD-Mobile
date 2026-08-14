import '../models/revolve_models.dart';
import '../validation/revolve_validation.dart';

class RevolveRecommendation {
  const RevolveRecommendation({
    required this.title,
    required this.confidence,
    required this.explanation,
    required this.impact,
    required this.alternatives,
    required this.advantages,
    required this.disadvantages,
  });
  final String title, explanation, impact;
  final int confidence;
  final List<String> alternatives, advantages, disadvantages;
}

class RevolveAdvisor {
  const RevolveAdvisor();
  List<RevolveRecommendation> analyze(
    RevolveFeature f,
    RevolveValidationResult v,
  ) {
    final out = <RevolveRecommendation>[];
    if (f.parameters.angle.abs() < 360) {
      out.add(
        const RevolveRecommendation(
          title: 'Review partial angle',
          confidence: 82,
          explanation:
              'A partial revolve may be intentional or replaced by a full revolution',
          impact: 'Clarifies design intent',
          alternatives: ['Full Revolve', 'Symmetric Revolve'],
          advantages: ['Controlled angular extent'],
          disadvantages: ['Additional angular faces'],
        ),
      );
    }
    if (v.issues.isNotEmpty) {
      out.add(
        RevolveRecommendation(
          title: 'Resolve revolve diagnostics',
          confidence: 96,
          explanation: '${v.issues.length} issues block safe execution',
          impact: 'Prevents failed native transactions',
          alternatives: const ['Select another axis', 'Repair profile'],
          advantages: const ['Stable topology'],
          disadvantages: const ['Requires user choice'],
        ),
      );
    }
    return out;
  }
}
