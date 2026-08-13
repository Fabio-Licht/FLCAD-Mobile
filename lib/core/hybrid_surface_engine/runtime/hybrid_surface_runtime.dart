import '../../engineering/runtime/engineering_runtime.dart';

class HybridRuntimeMetric {
  const HybridRuntimeMetric(this.operation, this.elapsed, this.success);
  final String operation;
  final Duration elapsed;
  final bool success;
}

class HybridSurfaceRuntime {
  HybridSurfaceRuntime({EngineeringRuntime? runtime})
    : runtime = runtime ?? EngineeringRuntime.shared;
  final EngineeringRuntime runtime;
  final List<HybridRuntimeMetric> metrics = [];
  Future<T> execute<T>(String operation, Future<T> Function() callback) async {
    final watch = Stopwatch()..start();
    try {
      final result = await runtime
          .submit(
            'hybrid-surface-$operation-${DateTime.now().microsecondsSinceEpoch}',
            callback,
            namespace: 'hybrid-surface',
            runInIsolate: false,
          )
          .future;
      watch.stop();
      metrics.add(HybridRuntimeMetric(operation, watch.elapsed, true));
      return result;
    } catch (_) {
      watch.stop();
      metrics.add(HybridRuntimeMetric(operation, watch.elapsed, false));
      rethrow;
    }
  }
}
