import '../../cad_kernel/runtime/kernel_runtime.dart';

class FeatureRuntime {
  FeatureRuntime({KernelRuntime? runtime})
    : runtime = runtime ?? KernelRuntime();
  final KernelRuntime runtime;
  Future<T> execute<T>(String operation, Future<T> Function() callback) =>
      runtime.run('cad-feature-$operation', callback, runInIsolate: false);
}
