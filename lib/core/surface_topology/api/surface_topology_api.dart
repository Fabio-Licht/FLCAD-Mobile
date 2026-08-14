import '../../surface_fitting/models/surface_fitting_models.dart';
import '../engine/surface_topology_engine.dart';
import '../models/surface_topology_models.dart';

class SurfaceTopologyApi {
  const SurfaceTopologyApi(this.engine);
  final SurfaceTopologyEngine engine;
  Future<SurfaceTopologyReport> build(
    SurfaceFittingReport fitting, {
    required String projectId,
  }) => engine.build(fitting, projectId: projectId);
  SurfaceTopologyReport? forFitting(String id) =>
      engine.repository.forFitting(id);
  Future<void> persist() => engine.repository.persist();
}
