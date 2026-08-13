import '../runtime/geometric_kernel_runtime.dart';

abstract interface class DistributedGeometryExecutor
    implements RemoteGeometricKernel {
  Stream<double> progress(String taskId);
  Future<void> cancel(String taskId);
}
