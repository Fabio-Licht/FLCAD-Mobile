import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../engine/surface_operations_engine.dart';
import '../models/surface_operation_models.dart';

class SurfaceOperationsApi {
  const SurfaceOperationsApi(this.engine);
  final SurfaceOperationsEngine engine;
  SurfaceOperation begin({
    required SurfaceOperationType type,
    required PatchEntity patch,
    Map<String, dynamic> parameters = const {},
    List<SurfaceConstraint> constraints = const [],
  }) => engine.begin(
    type: type,
    patch: patch,
    parameters: parameters,
    constraints: constraints,
  );
  SurfaceOperation preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) => engine.preview(id, topology, quality);
  SurfaceOperation validate(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) => engine.validate(id, topology, quality);
  Future<SurfaceOperation> commit(
    String id, {
    required String projectId,
    required SurfaceQualityReport quality,
  }) => engine.commit(id, projectId: projectId, quality: quality);
  Future<SurfaceOperation> rollback(String id) => engine.rollback(id);
  SurfaceOperation cancel(String id) => engine.cancel(id);
  Iterable<SurfaceOperation> get operations =>
      engine.repository.operations.values;
  Future<void> persist() =>
      engine.repository.persist(engine.analytics.toJson());
}
