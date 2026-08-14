import '../models/validation_models.dart';
import '../preview/heat_map.dart';

class ValidationRecommendation {
  const ValidationRecommendation({
    required this.title,
    required this.confidence,
    required this.explanation,
    required this.priority,
    required this.expectedImprovement,
    required this.advantages,
    required this.disadvantages,
    required this.alternatives,
  });
  final String title, explanation, priority;
  final double confidence, expectedImprovement;
  final List<String> advantages, disadvantages, alternatives;
}

class ValidationAdvisor {
  const ValidationAdvisor();
  List<ValidationRecommendation> analyze(
    LiveValidationSession session,
    HeatMapPreview heatMap,
  ) => [
    ValidationRecommendation(
      title: heatMap.criticalRegions.isEmpty
          ? 'Preserve current strategy'
          : 'Correct critical regions first',
      confidence: session.metrics?.confidence ?? 0,
      explanation: heatMap.criticalRegions.isEmpty
          ? 'All sampled regions are below the critical threshold'
          : 'Critical deviation dominates expected quality',
      priority: heatMap.criticalRegions.isEmpty ? 'low' : 'high',
      expectedImprovement: session.metrics == null
          ? 0
          : 100 - session.metrics!.overallQuality,
      advantages: const ['Incremental', 'Traceable'],
      disadvantages: [
        if (session.metrics == null) 'Kernel measurements unavailable',
      ],
      alternatives: const [
        'Next Feature',
        'Datum refinement',
        'Alignment refinement',
        'Partial Best Fit',
      ],
    ),
  ];
}
