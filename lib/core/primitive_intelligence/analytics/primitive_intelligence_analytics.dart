import '../models/primitive_intelligence_models.dart';

class PrimitiveIntelligenceAnalytics {
  const PrimitiveIntelligenceAnalytics({
    required this.analysisDuration,
    required this.primitivesAnalyzed,
    required this.hypotheses,
    required this.accepted,
    required this.rejected,
    required this.averageConfidence,
    required this.performanceUnits,
  });
  final Duration analysisDuration;
  final int primitivesAnalyzed,
      hypotheses,
      accepted,
      rejected,
      performanceUnits;
  final double averageConfidence;
  factory PrimitiveIntelligenceAnalytics.fromSession(
    PrimitiveIntelligenceSession session, {
    Duration analysisDuration = Duration.zero,
  }) => PrimitiveIntelligenceAnalytics(
    analysisDuration: analysisDuration,
    primitivesAnalyzed: session.hypotheses
        .map((e) => e.primitive.id)
        .toSet()
        .length,
    hypotheses: session.hypotheses.length,
    accepted: session.decisions
        .where((e) => e.type == PrimitiveDecisionType.accepted)
        .length,
    rejected: session.decisions
        .where((e) => e.type == PrimitiveDecisionType.rejected)
        .length,
    averageConfidence: session.hypotheses.isEmpty
        ? 0
        : session.hypotheses.fold<double>(
                0,
                (sum, e) => sum + e.scores.confidence,
              ) /
              session.hypotheses.length,
    performanceUnits:
        session.hypotheses.fold<int>(
          0,
          (sum, e) => sum + 1 + e.evidence.length,
        ) +
        session.patterns.length,
  );
  Map<String, dynamic> toJson() => {
    'analysisMicros': analysisDuration.inMicroseconds,
    'primitivesAnalyzed': primitivesAnalyzed,
    'hypotheses': hypotheses,
    'accepted': accepted,
    'rejected': rejected,
    'averageConfidence': averageConfidence,
    'performanceUnits': performanceUnits,
  };
}
