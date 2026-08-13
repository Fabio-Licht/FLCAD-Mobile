import '../../smart_regions/models/geometry.dart';
import '../../smart_regions/models/smart_region.dart';
import '../engine/reference_engine.dart';
import '../models/reference_entity.dart';

class ReferenceApi {
  ReferenceApi({ReferenceEngine? engine})
    : _engine = engine ?? ReferenceEngine();
  final ReferenceEngine _engine;
  Future<ReferenceEntity> create({
    required String projectId,
    required String name,
    required ReferenceMode mode,
    required ReferenceRecipe recipe,
    Map<String, MeshTopology> meshes = const {},
    Map<String, SmartRegion> regions = const {},
  }) => _engine.create(
    projectId: projectId,
    name: name,
    mode: mode,
    recipe: recipe,
    meshes: meshes,
    regions: regions,
  );
  Future<List<ReferenceEntity>> list(String projectId) =>
      _engine.repository.load(projectId);
  Future<ReferenceEntity> rebuild(
    ReferenceEntity r, {
    Map<String, MeshTopology> meshes = const {},
    Map<String, SmartRegion> regions = const {},
  }) => _engine.rebuild(r, meshes: meshes, regions: regions);
  Future<void> delete(ReferenceEntity r) => _engine.delete(r);
  Future<void> restore(ReferenceEntity r) => _engine.restore(r);
  Future<bool> validate(ReferenceEntity r) => _engine.validate(r);
}
