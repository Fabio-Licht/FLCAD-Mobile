import '../models/mesh_models.dart';

class MeshStatistics {
  const MeshStatistics();
  Map<String, dynamic> calculate(MeshEntity mesh) => {
    'vertices': mesh.vertexCount,
    'triangles': mesh.triangleCount,
    'fileBytes': mesh.fileSize,
    'estimatedNativeBytes': mesh.vertexCount * 24 + mesh.triangleCount * 12,
    'bounds': mesh.bounds.toJson(),
    'trianglesPerVertex': mesh.vertexCount == 0
        ? 0
        : mesh.triangleCount / mesh.vertexCount,
  };
}
