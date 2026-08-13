import '../../cad_kernel/runtime/kernel_runtime.dart';

class SurfaceGenerationRuntime {
  SurfaceGenerationRuntime({KernelRuntime? runtime})
    : runtime = runtime ?? KernelRuntime();
  final KernelRuntime runtime;
  Future<T> execute<T>(String operation, Future<T> Function() callback) =>
      runtime.run(
        'surface-generation-$operation',
        callback,
        runInIsolate: false,
      );
}
