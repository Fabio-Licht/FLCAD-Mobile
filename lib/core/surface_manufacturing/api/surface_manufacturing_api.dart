import '../../surface_boundary/models/surface_boundary_models.dart';
import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../engine/surface_manufacturing_engine.dart';
import '../models/surface_manufacturing_models.dart';

class SurfaceManufacturingApi {
  const SurfaceManufacturingApi(this.engine);
  final SurfaceManufacturingEngine engine;
  SurfaceManufacturingSession begin({
    required ManufacturingOperationType type,
    required PatchEntity patch,
    required ManufacturingIntent intent,
    Map<String, dynamic> parameters = const {},
    List<SurfaceConstraint> constraints = const [],
    List<BoundaryFixedRegion> fixedRegions = const [],
  }) => engine.begin(
    type: type,
    patch: patch,
    intent: intent,
    parameters: parameters,
    constraints: constraints,
    fixedRegions: fixedRegions,
  );
  SurfaceManufacturingSession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) => engine.preview(id, topology, quality);
  SurfaceManufacturingSession validate(String id) => engine.validate(id);
  Future<SurfaceManufacturingSession> commit(
    String id, {
    required SurfaceTopologyReport topology,
    required SurfaceQualityReport quality,
    required String projectId,
  }) => engine.commit(
    id,
    topology: topology,
    quality: quality,
    projectId: projectId,
  );
  Future<SurfaceManufacturingSession> rollback(String id) =>
      engine.rollback(id);
  SurfaceManufacturingSession cancel(String id) => engine.cancel(id);
  Future<void> persist() => engine.repository.persist(engine.analytics);
  Iterable<SurfaceManufacturingSession> get sessions =>
      engine.repository.sessions.values;
}
