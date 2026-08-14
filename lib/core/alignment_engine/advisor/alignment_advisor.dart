import '../models/alignment_models.dart';
import '../preview/alignment_preview.dart';

class AlignmentRecommendation {
  const AlignmentRecommendation({
    required this.title,
    required this.confidence,
    required this.explanation,
    required this.advantages,
    required this.disadvantages,
    required this.expectedAccuracy,
    required this.impact,
    required this.alternatives,
  });
  final String title, explanation, impact;
  final double confidence, expectedAccuracy;
  final List<String> advantages, disadvantages, alternatives;
}

class AlignmentAdvisor {
  const AlignmentAdvisor();
  List<AlignmentRecommendation> analyze(
    Alignment alignment,
    AlignmentPreview preview,
  ) => [
    AlignmentRecommendation(
      title: alignment.type == AlignmentType.icp
          ? 'Partial Best Fit strategy'
          : 'Reference alignment strategy',
      confidence: preview.confidence,
      explanation:
          'Use stable planes, axes and origins before iterative refinement',
      advantages: const ['Traceable', 'Repeatable'],
      disadvantages: [if (preview.rmsError > .2) 'Possible precision loss'],
      expectedAccuracy: 1 - preview.rmsError,
      impact:
          'Locks ${alignment.parameters.lockedAxes.length} axes and preserves confirmation',
      alternatives: const ['Best Fit', 'ICP', 'Plane + Axis'],
    ),
  ];
}
