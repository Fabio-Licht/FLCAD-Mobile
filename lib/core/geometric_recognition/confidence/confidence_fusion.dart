import '../models/recognition_models.dart';

class RecognitionConfidenceFusion {
  const RecognitionConfidenceFusion();
  double fuse(RecognitionContext context, RecognitionCandidate candidate) {
    final signals = <double>[
      candidate.statistics.score,
      candidate.statistics.coverage,
      candidate.statistics.stability,
      context.historicalSuccess,
      context.areiConfidence,
      context.knowledgeConfidence,
      context.cognitionConfidence,
      context.decisionConfidence,
    ];
    final available = signals.where((value) => value > 0).toList();
    if (available.isEmpty) return 0;
    return (available.fold<double>(0, (a, b) => a + b) / available.length)
        .clamp(0, 1);
  }
}
