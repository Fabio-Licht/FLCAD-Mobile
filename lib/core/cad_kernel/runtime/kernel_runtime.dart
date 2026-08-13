import '../../engineering/runtime/engineering_runtime.dart';
import '../analytics/kernel_analytics.dart';
import '../models/kernel_models.dart';

class KernelRuntime {
  KernelRuntime({EngineeringRuntime? runtime, KernelAnalytics? analytics})
    : runtime = runtime ?? EngineeringRuntime.shared,
      analytics = analytics ?? KernelAnalytics();
  final EngineeringRuntime runtime;
  final KernelAnalytics analytics;
  Future<T> run<T>(
    String id,
    Future<T> Function() operation, {
    int entityCount = 0,
    bool runInIsolate = true,
  }) async {
    final watch = Stopwatch()..start();
    try {
      final result = await runtime
          .submit(
            id,
            operation,
            namespace: 'geometry',
            priority: EngineeringTaskPriority.high,
            runInIsolate: runInIsolate,
          )
          .future;
      watch.stop();
      analytics.record(
        KernelMetric(id, watch.elapsed, 0, entityCount, true, DateTime.now()),
      );
      return result;
    } catch (_) {
      watch.stop();
      analytics.record(
        KernelMetric(id, watch.elapsed, 0, entityCount, false, DateTime.now()),
      );
      rethrow;
    }
  }
}
