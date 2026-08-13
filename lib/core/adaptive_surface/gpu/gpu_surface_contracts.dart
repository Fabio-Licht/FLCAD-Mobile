import '../builders/surface_builder.dart';

enum GPUBackend { cuda, metal, vulkan, openCl }

abstract interface class GPUSurfaceSolver {
  GPUBackend get backend;
  Future<SurfaceCandidate> solve(SurfaceBuildRequest request);
}
