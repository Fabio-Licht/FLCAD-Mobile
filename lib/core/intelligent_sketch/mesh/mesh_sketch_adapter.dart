import '../../smart_regions/models/geometry.dart';
import '../adapters/sketch_geometry_adapter.dart';
import '../models/sketch_context.dart';

class MeshSketchAdapter implements SketchGeometryAdapter {
  const MeshSketchAdapter(this.meshes);
  final Map<String, MeshTopology> meshes;
  @override
  SketchContextKind get kind => SketchContextKind.mesh;
  @override
  Future<String> fingerprint(String id) async {
    final mesh = meshes[id];
    if (mesh == null) throw StateError('Mesh not found');
    return '${mesh.id}:${mesh.vertices.length}:${mesh.triangles.length}';
  }

  @override
  Future<SketchAnchor> project(Vec3 point, String sourceId) async {
    final mesh = meshes[sourceId];
    if (mesh == null || mesh.vertices.isEmpty) {
      throw StateError('Mesh not found');
    }
    var index = 0, distance = (mesh.vertices.first - point).length;
    for (var i = 1; i < mesh.vertices.length; i++) {
      final candidate = (mesh.vertices[i] - point).length;
      if (candidate < distance) {
        distance = candidate;
        index = i;
      }
    }
    return SketchAnchor(
      position: mesh.vertices[index],
      contextId: sourceId,
      primitiveIndex: index,
    );
  }

  @override
  Future<Vec3> normalAt(SketchAnchor anchor) async => const Vec3(0, 0, 1);
}
