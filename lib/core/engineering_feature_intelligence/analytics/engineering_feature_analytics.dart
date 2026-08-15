import '../models/engineering_feature_models.dart';

class EngineeringFeatureAnalytics {
  const EngineeringFeatureAnalytics({
    required this.analysisDuration,
    required this.featuresRecognized,
    required this.hypotheses,
    required this.accepted,
    required this.rejected,
    required this.patterns,
    required this.averageConfidence,
    required this.performanceUnits,
  });
  final Duration analysisDuration;
  final int featuresRecognized,
      hypotheses,
      accepted,
      rejected,
      patterns,
      performanceUnits;
  final double averageConfidence;
  factory EngineeringFeatureAnalytics.fromSession(
    EngineeringFeatureSession session, {
    Duration analysisDuration = Duration.zero,
  }) => EngineeringFeatureAnalytics(
    analysisDuration: analysisDuration,
    featuresRecognized: session.hypotheses.map((e) => e.type).toSet().length,
    hypotheses: session.hypotheses.length,
    accepted: session.decisions
        .where((e) => e.type == FeatureDecisionType.accepted)
        .length,
    rejected: session.decisions
        .where((e) => e.type == FeatureDecisionType.rejected)
        .length,
    patterns: session.hypotheses
        .expand((e) => e.graph.nodes)
        .where((e) => e.kind == 'pattern')
        .length,
    averageConfidence: session.hypotheses.isEmpty
        ? 0
        : session.hypotheses.fold<double>(
                0,
                (sum, e) => sum + e.scores.overallConfidence,
              ) /
              session.hypotheses.length,
    performanceUnits: session.hypotheses.fold<int>(
      0,
      (sum, e) => sum + e.graph.nodes.length + e.evidence.length,
    ),
  );
  Map<String, dynamic> toJson() => {
    'analysisMicros': analysisDuration.inMicroseconds,
    'featuresRecognized': featuresRecognized,
    'hypotheses': hypotheses,
    'accepted': accepted,
    'rejected': rejected,
    'patterns': patterns,
    'averageConfidence': averageConfidence,
    'performanceUnits': performanceUnits,
  };
}
