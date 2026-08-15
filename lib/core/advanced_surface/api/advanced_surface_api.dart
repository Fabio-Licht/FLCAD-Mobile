import '../../surface_boundary/models/surface_boundary_models.dart';
import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_manufacturing/models/surface_manufacturing_models.dart';
import '../../surface_operations/models/surface_operation_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../engine/advanced_surface_engine.dart';
import '../models/advanced_surface_models.dart';

class AdvancedSurfaceApi {
  const AdvancedSurfaceApi(this.engine);
  final AdvancedSurfaceEngine engine;
  AdvancedSurfaceSession begin({
    required AdvancedSurfaceType type,
    required PatchEntity targetPatch,
    List<PatchEntity> selectedPatches = const [],
    AdvancedSelectionType selectionType = AdvancedSelectionType.patch,
    AdvancedContinuity continuity = AdvancedContinuity.g1,
    Map<String, dynamic> parameters = const {},
    List<SurfaceConstraint> constraints = const [],
    List<BoundaryFixedRegion> fixedRegions = const [],
    ManufacturingIntent? manufacturingIntent,
  }) => engine.begin(
    type: type,
    targetPatch: targetPatch,
    selectedPatches: selectedPatches,
    selectionType: selectionType,
    continuity: continuity,
    parameters: parameters,
    constraints: constraints,
    fixedRegions: fixedRegions,
    manufacturingIntent: manufacturingIntent,
  );
  AdvancedSurfaceSession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) => engine.preview(id, topology, quality);
  AdvancedSurfaceSession validate(String id) => engine.validate(id);
  Future<AdvancedSurfaceSession> commit(
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
  Future<AdvancedSurfaceSession> rollback(String id) => engine.rollback(id);
  AdvancedSurfaceSession cancel(String id) => engine.cancel(id);
  Future<void> persist() => engine.repository.persist(engine.analytics);
  Iterable<AdvancedSurfaceSession> get sessions =>
      engine.repository.sessions.values;
}
