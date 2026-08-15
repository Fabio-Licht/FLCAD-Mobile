import '../advisor/reference_strategy_advisor.dart';
import '../analytics/smart_reference_analytics.dart';
import '../models/smart_reference_models.dart';

class SmartReferenceWorkspace {
  SmartReferenceWorkspace({
    required this.session,
    required Iterable<ReferenceRecommendation> recommendations,
    required this.analytics,
  }) : recommendations = List.unmodifiable(recommendations);
  final SmartReferenceSession session;
  final List<ReferenceRecommendation> recommendations;
  final SmartReferenceAnalytics analytics;
  List<String> get panels => const [
    'Candidates',
    'Ranking',
    'Strategies',
    'Graphs',
    'Justifications',
    'Alignments',
    'Smart References',
  ];
  Map<String, dynamic> get propertyInspector {
    final current = session.candidates.isEmpty
        ? null
        : session.candidates.first;
    return {
      'Panel': 'Smart References',
      'Type': current?.type.name,
      'Confidence': current?.scores.overallConfidence,
      'Justification': current?.justification,
      'Feature Graph Related': current?.featureIds,
      'Primitive Graph Related': current?.primitiveIds,
      'Alignment Strategy': session.strategies.map((e) => e.toJson()).toList(),
      'Reference Graph': session.graph.toJson(),
      'Recommendations': recommendations.map((e) => e.toJson()).toList(),
      'Analytics': analytics.toJson(),
      'Geometry Modified': false,
    };
  }
}
