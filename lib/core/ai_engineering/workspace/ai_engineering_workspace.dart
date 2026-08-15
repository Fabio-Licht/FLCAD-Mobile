import '../analytics/ai_engineering_analytics.dart';
import '../models/ai_engineering_models.dart';

class AIEngineeringWorkspace {
  AIEngineeringWorkspace({
    required this.session,
    required Iterable<AIRecommendation> recommendations,
    required this.analytics,
  }) : recommendations = List.unmodifiable(recommendations);
  final IntentSession session;
  final List<AIRecommendation> recommendations;
  final AIEngineeringAnalytics analytics;
  List<String> get panels => const [
    'Session',
    'Timeline',
    'Analytics',
    'Live Reconstruction',
    'Surface Operations',
    'Recognition',
    'Property Inspector',
  ];
  Map<String, dynamic> get propertyInspector {
    final current = session.intent.candidates.isEmpty
        ? null
        : session.intent.candidates.first;
    return {
      'Context': session.context.toJson(),
      'Current Hypothesis': current?.toJson(),
      'Confidence': current?.confidence.toJson(),
      'Recommendations': recommendations.map((e) => e.toJson()).toList(),
      'Evidence': current?.evidence.map((e) => e.toJson()).toList() ?? const [],
      'Technical Justification': current?.rationale,
      'Analytics': analytics.toJson(),
      'Consultative Only': true,
      'Geometry Modified': false,
    };
  }
}
