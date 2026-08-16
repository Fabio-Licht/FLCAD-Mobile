import 'dart:math' as math;

import '../../../core/geometric_kernel/geometry/vectors.dart';
import '../contracts/bridge_selection.dart';

class MeshHitTesting {
  const MeshHitTesting();
  MeshHit? hit(BridgeSelection selection, MeshRay ray) {
    MeshHit? nearest;
    for (final triangle in selection.triangleIndices) {
      final indices = selection.geometry.triangles;
      final offset = triangle * 3;
      if (offset + 2 >= indices.length) continue;
      final a = _point(selection, indices[offset]);
      final b = _point(selection, indices[offset + 1]);
      final c = _point(selection, indices[offset + 2]);
      final distance = _intersection(ray, a, b, c);
      if (distance != null &&
          (nearest == null || distance < nearest.distance)) {
        nearest = MeshHit(
          triangleIndex: triangle,
          point: ray.origin + ray.direction * distance,
          distance: distance,
        );
      }
    }
    return nearest;
  }

  Vector3 _point(BridgeSelection selection, int vertex) {
    final values = selection.geometry.nodes, offset = vertex * 3;
    return Vector3(values[offset], values[offset + 1], values[offset + 2]);
  }

  double? _intersection(MeshRay ray, Vector3 a, Vector3 b, Vector3 c) {
    const epsilon = 1e-10;
    final edge1 = b - a, edge2 = c - a;
    final h = ray.direction.cross(edge2), determinant = edge1.dot(h);
    if (determinant.abs() < epsilon) return null;
    final inverse = 1 / determinant, s = ray.origin - a;
    final u = inverse * s.dot(h);
    if (u < 0 || u > 1) return null;
    final q = s.cross(edge1), v = inverse * ray.direction.dot(q);
    if (v < 0 || u + v > 1) return null;
    final distance = inverse * edge2.dot(q);
    return distance > math.max(epsilon, 0) ? distance : null;
  }
}
