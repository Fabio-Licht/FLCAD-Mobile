import '../../cad_kernel/analytics/kernel_analytics.dart';
import '../../cad_kernel/runtime/kernel_runtime.dart';

class CadBuilderRuntime {
  CadBuilderRuntime({KernelRuntime? kernelRuntime})
    : kernelRuntime = kernelRuntime ?? KernelRuntime();
  final KernelRuntime kernelRuntime;
  KernelAnalytics get analytics => kernelRuntime.analytics;
  Future<T> execute<T>(String operation, Future<T> Function() callback) =>
      kernelRuntime.run(
        'cad-builder-$operation',
        callback,
        runInIsolate: false,
      );
}
