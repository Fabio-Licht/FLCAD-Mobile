import '../runtime/geometric_kernel_runtime.dart';

enum GpuApi { cuda, vulkan, metal, openCl, webGpu }

abstract interface class GpuGeometricBackend
    implements GeometricComputeBackend {
  GpuApi get api;
}
