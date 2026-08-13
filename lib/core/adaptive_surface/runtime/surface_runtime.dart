import 'dart:isolate';
import '../builders/surface_builder.dart';
import '../solver/adaptive_surface_solver.dart';

abstract interface class SurfaceComputeRuntime {
  Future<SurfaceSolverResult> solve(SurfaceBuildRequest request);
}

class IsolateSurfaceRuntime implements SurfaceComputeRuntime {
  IsolateSurfaceRuntime(this.builders);
  final List<SurfaceBuilder> builders;
  @override
  Future<SurfaceSolverResult> solve(SurfaceBuildRequest request) =>
      Isolate.run(() => AdaptiveSurfaceSolver(builders).solve(request));
}
