import '../advisor/engineering_feature_advisor.dart';
import '../analytics/engineering_feature_analytics.dart';
import '../models/engineering_feature_models.dart';

class EngineeringFeatureWorkspace {
  EngineeringFeatureWorkspace({
    required this.session,
    required Iterable<EngineeringFeatureRecommendation> recommendations,
    required this.analytics,
  }) : recommendations = List.unmodifiable(recommendations);
  final EngineeringFeatureSession session;
  final List<EngineeringFeatureRecommendation> recommendations;
  final EngineeringFeatureAnalytics analytics;
  List<String> get panels => const [
    'Feature Tree',
    'Confidence Tree',
    'Justifications',
    'Evidence',
    'Ranking',
    'Context',
    'Engineering Features',
  ];
  Map<String, dynamic> get propertyInspector {
    final current = session.hypotheses.isEmpty
        ? null
        : session.hypotheses.first;
    return {
      'Panel': 'Engineering Features',
      'Type': current?.type.name,
      'Function': current?.function.name,
      'Feature Tree': current?.graph.toJson(),
      'Primitive Tree':
          current?.graph.nodes
              .where(
                (e) => !const {'axis', 'symmetry', 'pattern'}.contains(e.kind),
              )
              .map((e) => e.toJson())
              .toList() ??
          const [],
      'Context': session.context.toJson(),
      'Confidence': current?.confidenceTree.toJson(),
      'Suggested Strategy': current?.strategy.toJson(),
      'Engineering DNA': session.dna.toJson(),
      'Recommendations': recommendations.map((e) => e.toJson()).toList(),
      'Analytics': analytics.toJson(),
      'Geometry Modified': false,
    };
  }
}
