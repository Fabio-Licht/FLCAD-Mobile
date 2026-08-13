import '../models/geometry.dart';
import '../selection/triangle_selection.dart';

class SmartBorderEngine {
  const SmartBorderEngine();
  TriangleSelection expand(
    MeshTopology mesh,
    TriangleSelection region, {
    int rings = 1,
  }) {
    var result = region;
    for (var r = 0; r < rings; r++) {
      final added = <int>{...result.indices};
      for (final i in result.indices) {
        added.addAll(mesh.triangleNeighbors[i]);
      }
      result = TriangleSelection(added);
    }
    return result;
  }

  TriangleSelection shrink(
    MeshTopology mesh,
    TriangleSelection region, {
    int rings = 1,
  }) {
    var result = region;
    for (var r = 0; r < rings; r++) {
      final boundary = result.indices
          .where(
            (i) => mesh.triangleNeighbors[i].any((n) => !result.contains(n)),
          )
          .toSet();
      result = TriangleSelection(result.indices.difference(boundary));
    }
    return result;
  }

  TriangleSelection smooth(
    MeshTopology mesh,
    TriangleSelection region, {
    int iterations = 1,
  }) {
    var result = region;
    for (var i = 0; i < iterations; i++) {
      final candidates = <int>{};
      for (final t in result.indices) {
        candidates.addAll(mesh.triangleNeighbors[t]);
      }
      final next = <int>{};
      for (final t in candidates.union(result.indices)) {
        final neighbors = mesh.triangleNeighbors[t];
        final inside = neighbors.where(result.contains).length;
        if (inside * 2 >= neighbors.length) next.add(t);
      }
      result = TriangleSelection(next);
    }
    return result;
  }

  TriangleSelection relax(MeshTopology mesh, TriangleSelection region) =>
      smooth(mesh, expand(mesh, region), iterations: 1);
  TriangleSelection preserve(
    MeshTopology mesh,
    TriangleSelection original,
    TriangleSelection candidate,
  ) => TriangleSelection(
    candidate.indices.where(
      (i) =>
          original.contains(i) ||
          mesh.triangleNeighbors[i].any(original.contains),
    ),
  );
}
