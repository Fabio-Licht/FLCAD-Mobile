import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../engine/surface_fair_engine.dart';
import '../models/surface_fair_models.dart';

class SurfaceFairApi {
  const SurfaceFairApi(this.engine);
  final SurfaceFairEngine engine;
  SurfaceFairSession begin({
    required FairType type,
    required PatchEntity patch,
    Map<String, dynamic> parameters = const {},
    List<SurfaceConstraint> constraints = const [],
    List<FairFixedRegion> fixedRegions = const [],
    FairContinuity transition = FairContinuity.g2,
  }) => engine.begin(
    type: type,
    patch: patch,
    parameters: parameters,
    constraints: constraints,
    fixedRegions: fixedRegions,
    transition: transition,
  );
  SurfaceFairSession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) => engine.preview(id, topology, quality);
  SurfaceFairSession validate(String id) => engine.validate(id);
  Future<SurfaceFairSession> commit(
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
  Future<SurfaceFairSession> rollback(String id) => engine.rollback(id);
  SurfaceFairSession cancel(String id) => engine.cancel(id);
  Future<void> persist() => engine.repository.persist(engine.analytics);
  Iterable<SurfaceFairSession> get sessions =>
      engine.repository.sessions.values;
}
