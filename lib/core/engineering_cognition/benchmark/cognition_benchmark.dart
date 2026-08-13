import '../../reverse_intelligence/models/intelligence_models.dart';
import '../orchestrator/cognition_orchestrator.dart';

class CognitionBenchmarkResult {
  const CognitionBenchmarkResult(this.elapsed, this.featureCount);
  final Duration elapsed;
  final int featureCount;
}

class CognitionBenchmark {
  const CognitionBenchmark();
  CognitionBenchmarkResult run(ReasoningSnapshot arei) {
    final watch = Stopwatch()..start(),
        result = EngineeringCognitionOrchestrator().analyze(arei);
    watch.stop();
    return CognitionBenchmarkResult(
      watch.elapsed,
      result.snapshot.features.length,
    );
  }
}
