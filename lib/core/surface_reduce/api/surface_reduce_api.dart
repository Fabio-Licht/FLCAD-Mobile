import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../engine/surface_reduce_engine.dart';
import '../models/surface_reduce_models.dart';

class SurfaceReduceApi {
  const SurfaceReduceApi(this.engine);
  final SurfaceReduceEngine engine;
  SurfaceReduceSession begin({
    required ReduceType type,
    required PatchEntity patch,
    Map<String, dynamic> parameters = const {},
    List<SurfaceConstraint> constraints = const [],
    List<FixedRegion> fixedRegions = const [],
    ReduceContinuity transition = ReduceContinuity.g1,
  }) => engine.begin(
    type: type,
    patch: patch,
    parameters: parameters,
    constraints: constraints,
    fixedRegions: fixedRegions,
    transition: transition,
  );
  SurfaceReduceSession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) => engine.preview(id, topology, quality);
  SurfaceReduceSession validate(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) => engine.validate(id, topology, quality);
  Future<SurfaceReduceSession> commit(
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
  Future<SurfaceReduceSession> rollback(String id) => engine.rollback(id);
  SurfaceReduceSession cancel(String id) => engine.cancel(id);
  Future<void> persist() => engine.repository.persist(engine.analytics);
  Iterable<SurfaceReduceSession> get sessions =>
      engine.repository.sessions.values;
}
