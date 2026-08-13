import '../../engineering/runtime/engineering_runtime.dart';
import '../../reverse_intelligence/models/intelligence_models.dart';
import '../orchestrator/cognition_orchestrator.dart';

class CognitionCancellationToken {
  bool _cancelled = false;
  void cancel() => _cancelled = true;
  void check() {
    if (_cancelled) throw StateError('Cognition task cancelled');
  }
}

class CognitionRuntime {
  const CognitionRuntime();
  Future<CognitionResult> analyze(
    ReasoningSnapshot arei, {
    CognitionCancellationToken? cancellation,
  }) async {
    cancellation?.check();
    final result = await EngineeringRuntime.shared
        .submit(
          'cognition:${DateTime.now().microsecondsSinceEpoch}',
          () => EngineeringCognitionOrchestrator().analyze(arei),
          namespace: 'cognition',
        )
        .future;
    cancellation?.check();
    return result;
  }
}
