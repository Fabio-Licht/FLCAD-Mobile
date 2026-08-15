import '../models/smart_reference_models.dart';

class SmartReferenceAnalytics {
  const SmartReferenceAnalytics({
    required this.analysisDuration,
    required this.suggested,
    required this.accepted,
    required this.rejected,
    required this.strategiesGenerated,
    required this.averageConfidence,
    required this.performanceUnits,
  });
  final Duration analysisDuration;
  final int suggested,
      accepted,
      rejected,
      strategiesGenerated,
      performanceUnits;
  final double averageConfidence;
  factory SmartReferenceAnalytics.fromSession(
    SmartReferenceSession session, {
    Duration analysisDuration = Duration.zero,
  }) => SmartReferenceAnalytics(
    analysisDuration: analysisDuration,
    suggested: session.candidates.length,
    accepted: session.decisions
        .where((e) => e.type == ReferenceDecisionType.accepted)
        .length,
    rejected: session.decisions
        .where((e) => e.type == ReferenceDecisionType.rejected)
        .length,
    strategiesGenerated: session.strategies.length,
    averageConfidence: session.candidates.isEmpty
        ? 0
        : session.candidates.fold<double>(
                0,
                (sum, e) => sum + e.scores.overallConfidence,
              ) /
              session.candidates.length,
    performanceUnits:
        session.candidates.fold<int>(
          0,
          (sum, e) => sum + e.evidence.length + 1,
        ) +
        session.graph.dependencies.length +
        session.strategies.length,
  );
  Map<String, dynamic> toJson() => {
    'analysisMicros': analysisDuration.inMicroseconds,
    'referencesSuggested': suggested,
    'accepted': accepted,
    'rejected': rejected,
    'averageConfidence': averageConfidence,
    'strategiesGenerated': strategiesGenerated,
    'performanceUnits': performanceUnits,
  };
}
