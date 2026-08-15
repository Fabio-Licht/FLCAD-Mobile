import '../advisor/reconstruction_advisor.dart';
import '../analytics/reconstruction_strategy_analytics.dart';
import '../models/reconstruction_strategy_models.dart';

class ReconstructionStrategyWorkspace {
  ReconstructionStrategyWorkspace({
    required this.session,
    required Iterable<ReconstructionRecommendation> recommendations,
    required this.analytics,
  }) : recommendations = List.unmodifiable(recommendations);
  final ReconstructionStrategySession session;
  final List<ReconstructionRecommendation> recommendations;
  final ReconstructionStrategyAnalytics analytics;
  List<String> get panels => const [
    'Strategies',
    'Playbook',
    'Steps',
    'Dependencies',
    'Difficulties',
    'Confidence',
    'Justifications',
    'Reconstruction Strategy',
  ];
  Map<String, dynamic> get propertyInspector {
    final active = session.strategies.isEmpty ? null : session.strategies.first;
    return {
      'Panel': 'Reconstruction Strategy',
      'Active Strategy': active?.name,
      'Confidence': active?.confidence,
      'Estimated Time': active?.estimatedDuration.inMinutes,
      'Complexity': active?.complexity,
      'Steps': active?.steps.map((e) => e.toJson()).toList() ?? const [],
      'Dependencies': active?.graph.toJson(),
      'Observations': active?.reasoning.toJson(),
      'Playbook': session.playbook.toJson(),
      'Difficulty': session.difficulty.toJson(),
      'Recommendations': recommendations.map((e) => e.toJson()).toList(),
      'Analytics': analytics.toJson(),
      'Geometry Modified': false,
    };
  }
}
