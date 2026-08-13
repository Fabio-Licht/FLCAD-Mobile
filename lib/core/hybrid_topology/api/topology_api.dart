import '../../smart_regions/models/geometry.dart';
import '../constraints/topology_constraint.dart';
import '../engine/hybrid_topology_engine.dart';
import '../hybrid/hybrid_object.dart';
import '../layers/mesh_layer.dart';
import '../morphing/mesh_morph_engine.dart';
import '../workspace/local_workspace.dart';

class TopologyApi {
  TopologyApi({HybridTopologyEngine? engine})
    : engine = engine ?? HybridTopologyEngine();
  final HybridTopologyEngine engine;
  Future<HybridObject> create({
    required String projectId,
    required String name,
    required GeometryAssetRef meshAsset,
    required MeshTopology mesh,
    List<String> regionIds = const [],
    List<String> referenceIds = const [],
    List<String> sketchIds = const [],
    List<String> surfaceIds = const [],
  }) => engine.create(
    projectId: projectId,
    name: name,
    meshAsset: meshAsset,
    mesh: mesh,
    regionIds: regionIds,
    referenceIds: referenceIds,
    sketchIds: sketchIds,
    surfaceIds: surfaceIds,
  );
  Future<HybridObject> morph(
    HybridObject o,
    MeshTopology m,
    MorphRequest r, {
    MeshLayerKind kind = MeshLayerKind.compensation,
  }) => engine.morph(o, m, r, kind: kind);
  void addConstraint(String id, TopologyConstraint c) =>
      engine.addConstraint(id, c);
  void addWorkspace(LocalWorkspace w) => engine.addWorkspace(w);
}
