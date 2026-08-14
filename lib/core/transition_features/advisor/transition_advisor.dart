import '../models/transition_models.dart';
import '../validation/transition_validation.dart';

class TransitionRecommendation {
  const TransitionRecommendation({
    required this.title,
    required this.confidence,
    required this.explanation,
    required this.impact,
    required this.alternatives,
    required this.advantages,
    required this.disadvantages,
  });
  final String title, explanation, impact;
  final double confidence;
  final List<String> alternatives, advantages, disadvantages;
}

class TransitionAdvisor {
  const TransitionAdvisor();
  List<TransitionRecommendation> analyze(
    TransitionFeature f,
    TransitionValidationResult result,
  ) => [
    TransitionRecommendation(
      title: f.family == TransitionFamily.sweep
          ? 'Path strategy'
          : 'Loft strategy',
      confidence: result.valid ? .9 : .7,
      explanation: result.valid
          ? 'References support the selected transition'
          : 'Resolve validation issues before confirmation',
      impact: result.valid ? 'Stable rebuild expected' : 'Execution may fail',
      alternatives: [
        f.family == TransitionFamily.sweep ? 'Loft' : 'Sweep',
        'Surface transition',
      ],
      advantages: const ['Parametric', 'Traceable'],
      disadvantages: [if (f.input.guideIds.isNotEmpty) 'Guide complexity'],
    ),
  ];
}
