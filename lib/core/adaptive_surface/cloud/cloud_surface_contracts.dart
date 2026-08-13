import '../builders/surface_builder.dart';

abstract interface class DistributedSurfaceSolver {
  Future<List<SurfaceCandidate>> solve(
    String projectId,
    SurfaceBuildRequest request,
  );
  Future<void> cancel(String operationId);
}
