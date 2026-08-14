import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../engine/live_reconstruction_engine.dart';
import '../models/live_reconstruction_models.dart';

class LiveReconstructionApi {
  const LiveReconstructionApi(this.engine);
  final LiveReconstructionEngine engine;
  LiveReconstruction begin(
    SurfaceOperation operation,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) => engine.begin(operation, topology, quality);
  LiveReconstruction preview(String id, SurfaceQualityReport quality) =>
      engine.preview(id, quality);
  LiveReconstruction validate(String id) => engine.validate(id);
  LiveReconstruction update(String id) => engine.update(id);
  Future<LiveReconstruction> commit(
    String id, {
    required String projectId,
    required SurfaceQualityReport quality,
  }) => engine.commit(id, projectId: projectId, quality: quality);
  Future<LiveReconstruction> rollback(String id) => engine.rollback(id);
  LiveReconstruction cancel(String id) => engine.cancel(id);
  Iterable<LiveReconstruction> get reconstructions =>
      engine.repository.reconstructions.values;
  Future<void> persist() =>
      engine.repository.persist(engine.analytics.toJson());
}
