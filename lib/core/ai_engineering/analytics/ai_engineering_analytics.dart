import '../models/ai_engineering_models.dart';

class AIEngineeringAnalytics {
  const AIEngineeringAnalytics({
    required this.analysisDuration,
    required this.hypothesisCount,
    required this.accepted,
    required this.rejected,
    required this.averageConfidence,
    required this.performanceUnits,
  });
  final Duration analysisDuration;
  final int hypothesisCount, accepted, rejected, performanceUnits;
  final double averageConfidence;
  factory AIEngineeringAnalytics.fromSession(
    IntentSession session, {
    Duration analysisDuration = Duration.zero,
  }) {
    final candidates = session.intent.candidates;
    final decisions = session.history.decisions;
    return AIEngineeringAnalytics(
      analysisDuration: analysisDuration,
      hypothesisCount: candidates.length,
      accepted: decisions
          .where((e) => e.type == IntentDecisionType.accepted)
          .length,
      rejected: decisions
          .where((e) => e.type == IntentDecisionType.rejected)
          .length,
      averageConfidence: candidates.isEmpty
          ? 0
          : candidates.fold<double>(
                  0,
                  (sum, item) => sum + item.confidence.score.overallConfidence,
                ) /
                candidates.length,
      performanceUnits:
          candidates.length +
          candidates.fold<int>(0, (sum, item) => sum + item.evidence.length),
    );
  }
  Map<String, dynamic> toJson() => {
    'analysisMicros': analysisDuration.inMicroseconds,
    'hypotheses': hypothesisCount,
    'accepted': accepted,
    'rejected': rejected,
    'averageConfidence': averageConfidence,
    'performanceUnits': performanceUnits,
  };
}
