import '../models/extrude_models.dart';
import '../validation/extrude_validation.dart';

class ExtrudeRecommendation {
  const ExtrudeRecommendation({
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

class ExtrudeAdvisor {
  const ExtrudeAdvisor();
  List<ExtrudeRecommendation> analyze(
    ExtrudeFeature f,
    ExtrudeValidationResult validation,
  ) {
    final out = <ExtrudeRecommendation>[];
    if (f.parameters.distance > 100) {
      out.add(
        const ExtrudeRecommendation(
          title: 'Review extrude distance',
          confidence: 82,
          explanation:
              'A long extrusion may not match the selected profile scale',
          impact: 'Improves manufacturability',
          alternatives: ['Up To Face', 'Two Directions'],
          advantages: ['Clear design extent'],
          disadvantages: ['Requires reference review'],
        ),
      );
    }
    if (validation.issues.isNotEmpty) {
      out.add(
        ExtrudeRecommendation(
          title: 'Resolve extrude warnings',
          confidence: 96,
          explanation:
              '${validation.issues.length} validation issues block safe execution',
          impact: 'Prevents failed kernel transactions',
          alternatives: const ['Repair profile', 'Change operation type'],
          advantages: const ['Traceable execution'],
          disadvantages: const ['Requires user decision'],
        ),
      );
    }
    return out;
  }
}
