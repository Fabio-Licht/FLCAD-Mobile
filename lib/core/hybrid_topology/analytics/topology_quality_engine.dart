import '../../smart_regions/models/geometry.dart';
import '../hybrid/hybrid_object.dart';

class TopologyQualityEngine {
  const TopologyQualityEngine();
  TopologyAnalytics analyze(MeshTopology mesh) {
    if (mesh.vertices.isEmpty) {
      return const TopologyAnalytics(
        thickness: 0,
        curvature: 0,
        noise: 1,
        continuity: 0,
        density: 0,
        quality: 0,
        confidence: 0,
        vertexCount: 0,
        faceCount: 0,
      );
    }
    final normals = List.generate(mesh.triangles.length, mesh.triangleNormal),
        average = normals.isEmpty
            ? const Vec3(0, 0, 1)
            : normals
                  .fold<Vec3>(const Vec3(0, 0, 0), (a, b) => a + b)
                  .normalized,
        noise = normals.isEmpty
            ? 0.0
            : normals
                      .map((n) => 1 - n.dot(average).abs())
                      .reduce((a, b) => a + b) /
                  normals.length,
        density = mesh.triangles.length / mesh.vertices.length,
        quality = (1 - noise).clamp(0, 1).toDouble();
    return TopologyAnalytics(
      thickness: 0,
      curvature: noise,
      noise: noise,
      continuity: quality,
      density: density,
      quality: quality,
      confidence: (mesh.vertices.length / 100).clamp(.1, 1).toDouble(),
      vertexCount: mesh.vertices.length,
      faceCount: mesh.triangles.length,
    );
  }
}
