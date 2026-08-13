import '../../engineering/runtime/engineering_runtime.dart';

class SurfaceRuntimeMetric {
  const SurfaceRuntimeMetric(this.operation, this.elapsed, this.success);
  final String operation;
  final Duration elapsed;
  final bool success;
}

class SurfaceIntelligenceRuntime {
  SurfaceIntelligenceRuntime({EngineeringRuntime? runtime})
    : runtime = runtime ?? EngineeringRuntime.shared;
  final EngineeringRuntime runtime;
  final List<SurfaceRuntimeMetric> metrics = [];
  Future<T> execute<T>(String operation, Future<T> Function() callback) async {
    final watch = Stopwatch()..start();
    try {
      final value = await runtime
          .submit(
            'surface-intelligence-$operation-${DateTime.now().microsecondsSinceEpoch}',
            callback,
            namespace: 'surface-intelligence',
            runInIsolate: false,
          )
          .future;
      watch.stop();
      metrics.add(SurfaceRuntimeMetric(operation, watch.elapsed, true));
      return value;
    } catch (_) {
      watch.stop();
      metrics.add(SurfaceRuntimeMetric(operation, watch.elapsed, false));
      rethrow;
    }
  }
}
