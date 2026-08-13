import 'dart:isolate';
import '../models/knowledge_models.dart';
import '../reasoning/engineering_reasoner.dart';

class KnowledgeCancellationToken {
  bool _cancelled = false;
  void cancel() => _cancelled = true;
  void check() {
    if (_cancelled) throw StateError('Knowledge reasoning cancelled');
  }
}

class KnowledgeRuntime {
  const KnowledgeRuntime();
  Future<EngineeringReasoningResult> reason(
    EngineeringCase value, {
    KnowledgeCancellationToken? cancellation,
  }) async {
    cancellation?.check();
    final result = await Isolate.run(() => EngineeringReasoner().reason(value));
    cancellation?.check();
    return result;
  }
}
