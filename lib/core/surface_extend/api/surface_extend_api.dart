import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_morph/models/surface_morph_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../engine/surface_extend_engine.dart';
import '../models/surface_extend_models.dart';

class SurfaceExtendApi {
  const SurfaceExtendApi(this.engine);
  final SurfaceExtendEngine engine;
  ExtendSession begin({
    required ExtendType type,
    required PatchEntity patch,
    required String boundaryId,
    required List<MorphAnchor> anchors,
    Map<String, dynamic> parameters = const {},
    String manufacturingIntent = '',
  }) => engine.begin(
    type: type,
    patch: patch,
    boundaryId: boundaryId,
    anchors: anchors,
    parameters: parameters,
    manufacturingIntent: manufacturingIntent,
  );
  ExtendSession preview(
    String id,
    SurfaceTopologyReport t,
    SurfaceQualityReport q,
  ) => engine.preview(id, t, q);
  ExtendSession validate(
    String id,
    SurfaceTopologyReport t,
    SurfaceQualityReport q,
  ) => engine.validate(id, t, q);
  Future<ExtendSession> commit(
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
  Future<ExtendSession> rollback(String id) => engine.rollback(id);
  ExtendSession cancel(String id) => engine.cancel(id);
  Future<void> persist() => engine.repository.persist(engine.analytics);
  Iterable<ExtendSession> get sessions => engine.repository.sessions.values;
}
