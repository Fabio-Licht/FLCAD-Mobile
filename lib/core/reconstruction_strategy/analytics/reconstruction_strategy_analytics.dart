import '../models/reconstruction_strategy_models.dart';

class ReconstructionStrategyAnalytics {
  const ReconstructionStrategyAnalytics({
    required this.strategiesGenerated,
    required this.accepted,
    required this.rejected,
    required this.edited,
    required this.totalEstimatedDuration,
    required this.averageComplexity,
    required this.averageConfidence,
  });
  final int strategiesGenerated, accepted, rejected, edited;
  final Duration totalEstimatedDuration;
  final double averageComplexity, averageConfidence;
  factory ReconstructionStrategyAnalytics.fromSession(
    ReconstructionStrategySession session,
  ) => ReconstructionStrategyAnalytics(
    strategiesGenerated: session.strategies.length,
    accepted: session.decisions
        .where((e) => e.type == StrategyDecisionType.accepted)
        .length,
    rejected: session.decisions
        .where((e) => e.type == StrategyDecisionType.rejected)
        .length,
    edited: session.decisions
        .where((e) => e.type == StrategyDecisionType.edited)
        .length,
    totalEstimatedDuration: Duration(
      minutes: session.strategies.fold<int>(
        0,
        (sum, e) => sum + e.estimatedDuration.inMinutes,
      ),
    ),
    averageComplexity: session.strategies.isEmpty
        ? 0
        : session.strategies.fold<double>(0, (sum, e) => sum + e.complexity) /
              session.strategies.length,
    averageConfidence: session.strategies.isEmpty
        ? 0
        : session.strategies.fold<double>(0, (sum, e) => sum + e.confidence) /
              session.strategies.length,
  );
  Map<String, dynamic> toJson() => {
    'strategiesGenerated': strategiesGenerated,
    'accepted': accepted,
    'rejected': rejected,
    'edited': edited,
    'totalEstimatedMinutes': totalEstimatedDuration.inMinutes,
    'averageComplexity': averageComplexity,
    'averageConfidence': averageConfidence,
    'timersUsed': false,
  };
}
