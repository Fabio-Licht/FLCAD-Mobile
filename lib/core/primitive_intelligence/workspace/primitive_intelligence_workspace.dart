import '../analytics/primitive_intelligence_analytics.dart';
import '../models/primitive_intelligence_models.dart';

class PrimitiveIntelligenceWorkspace {
  PrimitiveIntelligenceWorkspace({
    required this.session,
    required Iterable<PrimitiveRecommendation> recommendations,
    required this.analytics,
  }) : recommendations = List.unmodifiable(recommendations);
  final PrimitiveIntelligenceSession session;
  final List<PrimitiveRecommendation> recommendations;
  final PrimitiveIntelligenceAnalytics analytics;
  List<String> get panels => const [
    'Hypotheses',
    'Evidence',
    'Scores',
    'Ranking',
    'Justifications',
    'Primitive Intelligence',
  ];
  Map<String, dynamic> get propertyInspector {
    final current = session.hypotheses.isEmpty
        ? null
        : session.hypotheses.first;
    return {
      'Panel': 'Primitive Intelligence',
      'Classification': current?.function.name,
      'Probable Function': current?.function.name,
      'Confidence': current?.scores.confidence,
      'Suggested Alignment': current?.alignment?.toJson(),
      'Justification': current?.justification,
      'References Used':
          current?.evidence.map((e) => e.source).toList() ?? const [],
      'Ranking': session.hypotheses
          .map((e) => {'id': e.id, 'overall': e.scores.overall})
          .toList(),
      'Recommendations': recommendations.map((e) => e.toJson()).toList(),
      'Analytics': analytics.toJson(),
      'Geometry Modified': false,
    };
  }
}
