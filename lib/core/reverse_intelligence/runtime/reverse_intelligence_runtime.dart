import 'dart:isolate';
import '../../smart_regions/models/geometry.dart';
import '../brain/reverse_brain.dart';

class ReverseIntelligenceCancellation {
  bool _cancelled = false;
  bool get cancelled => _cancelled;
  void cancel() => _cancelled = true;
  void check() {
    if (_cancelled) throw StateError('AREI task cancelled');
  }
}

class ReverseIntelligenceRuntime {
  const ReverseIntelligenceRuntime();
  Future<ReverseBrainResult> analyze(
    String projectId,
    MeshTopology mesh, {
    ReverseIntelligenceCancellation? cancellation,
  }) async {
    cancellation?.check();
    final result = await Isolate.run(
      () => const ReverseBrain().reason(projectId, mesh),
    );
    cancellation?.check();
    return result;
  }
}
