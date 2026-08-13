import '../api/surface_api.dart';
import '../builders/surface_builder.dart';
import '../models/adaptive_surface.dart';
import '../repair/surface_repair_engine.dart';

sealed class SurfacePipelineStep {
  const SurfacePipelineStep();
}

class CreateSurfaceStep extends SurfacePipelineStep {
  const CreateSurfaceStep(this.name, this.request);
  final String name;
  final SurfaceBuildRequest request;
}

class RepairSurfaceStep extends SurfacePipelineStep {
  const RepairSurfaceStep(this.actions);
  final Set<SurfaceRepairAction> actions;
}

class RefineSurfaceStep extends SurfacePipelineStep {
  const RefineSurfaceStep(this.stage);
  final SurfaceStage stage;
}

class ValidateSurfaceStep extends SurfacePipelineStep {
  const ValidateSurfaceStep();
}

class SurfacePipeline {
  const SurfacePipeline(this.api);
  final SurfaceApi api;
  Future<AdaptiveSurface> execute(
    String projectId,
    List<SurfacePipelineStep> steps,
  ) async {
    AdaptiveSurface? current;
    for (final step in steps) {
      switch (step) {
        case CreateSurfaceStep s:
          current = await api.create(
            projectId: projectId,
            name: s.name,
            request: s.request,
          );
        case RepairSurfaceStep s:
          if (current == null) throw StateError('Surface not created');
          current = await api.repair(current, s.actions);
        case RefineSurfaceStep s:
          if (current == null) throw StateError('Surface not created');
          current = await api.refine(current, s.stage);
        case ValidateSurfaceStep _:
          if (current == null) throw StateError('Surface not created');
          if (!await api.validate(current)) {
            throw StateError('Surface validation failed');
          }
      }
    }
    if (current == null) throw StateError('Empty surface pipeline');
    return current;
  }
}
