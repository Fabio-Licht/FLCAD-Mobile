import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../engine/surface_boundary_engine.dart';
import '../models/surface_boundary_models.dart';

class SurfaceBoundaryApi {
  const SurfaceBoundaryApi(this.engine);
  final SurfaceBoundaryEngine engine;
  SurfaceBoundarySession begin({
    required BoundaryOperationType type,
    required PatchEntity patch,
    required BoundaryEntity boundary,
    Map<String, dynamic> parameters = const {},
    List<SurfaceConstraint> constraints = const [],
    List<BoundaryFixedRegion> fixedRegions = const [],
    BoundaryContinuity continuity = BoundaryContinuity.g1,
  }) => engine.begin(
    type: type,
    patch: patch,
    boundary: boundary,
    parameters: parameters,
    constraints: constraints,
    fixedRegions: fixedRegions,
    continuity: continuity,
  );
  SurfaceBoundarySession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) => engine.preview(id, topology, quality);
  SurfaceBoundarySession validate(String id) => engine.validate(id);
  Future<SurfaceBoundarySession> commit(
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
  Future<SurfaceBoundarySession> rollback(String id) => engine.rollback(id);
  SurfaceBoundarySession cancel(String id) => engine.cancel(id);
  Future<void> persist() => engine.repository.persist(engine.analytics);
  Iterable<SurfaceBoundarySession> get sessions =>
      engine.repository.sessions.values;
}
