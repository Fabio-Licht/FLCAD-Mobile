import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../engine/surface_morph_engine.dart';
import '../models/surface_morph_models.dart';

class SurfaceMorphApi {
  const SurfaceMorphApi(this.engine);
  final SurfaceMorphEngine engine;
  MorphSession begin({
    required MorphTool tool,
    required PatchEntity patch,
    required List<MorphAnchor> anchors,
    required double radius,
    required FalloffType falloff,
    List<MorphConstraintGroup> constraintGroups = const [],
    Map<String, dynamic> parameters = const {},
  }) => engine.begin(
    tool: tool,
    patch: patch,
    anchors: anchors,
    radius: radius,
    falloff: falloff,
    constraintGroups: constraintGroups,
    parameters: parameters,
  );
  MorphSession preview(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality, {
    List<double> customCurve = const [],
  }) => engine.preview(id, topology, quality, customCurve: customCurve);
  MorphSession validate(
    String id,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) => engine.validate(id, topology, quality);
  Future<MorphSession> commit(
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
  Future<MorphSession> rollback(String id) => engine.rollback(id);
  MorphSession cancel(String id) => engine.cancel(id);
  Iterable<MorphSession> get sessions => engine.repository.sessions.values;
  Future<void> persist() =>
      engine.repository.persist(engine.analytics.toJson());
}
