import '../../engineering/runtime/engineering_runtime.dart';
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
      EngineeringRuntime.shared
          .submit(
            'surface:${DateTime.now().microsecondsSinceEpoch}',
            () => AdaptiveSurfaceSolver(builders).solve(request),
            namespace: 'surface',
          )
          .future;
}
