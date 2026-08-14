import '../../surface_topology/models/surface_topology_models.dart';
import '../engine/surface_continuity_engine.dart';
import '../models/surface_continuity_models.dart';

class SurfaceContinuityApi {
  const SurfaceContinuityApi(this.engine);
  final SurfaceContinuityEngine engine;
  Future<SurfaceQualityReport> run(SurfaceTopologyReport topology) =>
      engine.analyze(topology);
  SurfaceQualityReport? forTopology(String id) =>
      engine.repository.forTopology(id);
  Future<void> persist() => engine.repository.persist();
}
