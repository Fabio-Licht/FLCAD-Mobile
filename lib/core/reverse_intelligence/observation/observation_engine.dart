import '../../geometric_kernel/adapters/smart_regions_geometry_adapter.dart';
import '../../geometric_kernel/geometry/primitives.dart';
import '../../geometric_kernel/geometry/vectors.dart';
import '../../smart_regions/models/geometry.dart';
import '../models/intelligence_models.dart';

class ObservationEngine {
  const ObservationEngine();
  MeshObservation observe(MeshTopology mesh) {
    if (mesh.vertices.isEmpty || mesh.triangles.isEmpty) {
      throw ArgumentError('Observation requires a non-empty mesh');
    }
    final vertices = mesh.vertices.map((v) => v.toKernel()).toList(),
        bounds = BoundingBox3.fromPoints(vertices),
        extents = bounds.max - bounds.min;
    var area = 0.0, normalSum = Vector3.zero;
    final edges = <(int, int), int>{};
    for (var i = 0; i < mesh.triangles.length; i++) {
      final t = mesh.triangles[i],
          triangle = Triangle3(vertices[t.a], vertices[t.b], vertices[t.c]);
      area += triangle.area;
      normalSum = normalSum + triangle.normal;
      for (final edge in [(t.a, t.b), (t.b, t.c), (t.c, t.a)]) {
        final key = edge.$1 < edge.$2 ? edge : (edge.$2, edge.$1);
        edges[key] = (edges[key] ?? 0) + 1;
      }
    }
    final meanNormal = normalSum / mesh.triangles.length.toDouble();
    var deviation = 0.0;
    for (var i = 0; i < mesh.triangles.length; i++) {
      final n = mesh.triangleNormal(i).toKernel();
      deviation += (n - meanNormal).lengthSquared;
    }
    deviation /= mesh.triangles.length;
    final volume = extents.x * extents.y * extents.z,
        boundary = edges.values.where((count) => count == 1).length,
        density = volume <= 0 ? 0.0 : mesh.triangles.length / volume,
        coherence = (1 / (1 + deviation)).clamp(0, 1).toDouble(),
        centroid =
            vertices.reduce((a, b) => a + b) / vertices.length.toDouble();
    final evidence = <Evidence>[
      Evidence(
        id: 'surface_area',
        description: 'Measured triangle surface area',
        value: area,
        source: 'mesh.topology',
        unit: 'project²',
      ),
      Evidence(
        id: 'bounding_volume',
        description: 'Axis-aligned bounding volume',
        value: volume,
        source: 'geometric_kernel',
        unit: 'project³',
      ),
      Evidence(
        id: 'mesh_density',
        description: 'Triangles per bounding volume',
        value: density,
        source: 'mesh.topology',
      ),
      Evidence(
        id: 'boundary_edges',
        description: 'Edges incident to one triangle',
        value: boundary.toDouble(),
        source: 'mesh.topology',
      ),
      Evidence(
        id: 'normal_coherence',
        description: 'Inverse variance of triangle normals',
        value: coherence,
        source: 'mesh.normals',
      ),
    ];
    return MeshObservation(
      meshId: mesh.id,
      vertexCount: mesh.vertices.length,
      triangleCount: mesh.triangles.length,
      surfaceArea: area,
      boundingVolume: volume,
      meshDensity: density,
      boundaryEdgeCount: boundary,
      normalCoherence: coherence,
      axisExtents: extents,
      centroid: centroid,
      evidence: evidence,
    );
  }
}
