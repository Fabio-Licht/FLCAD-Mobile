import '../models/geometry.dart';
import '../selection/triangle_selection.dart';

abstract interface class RegionFilter {
  String get expression;
  TriangleSelection evaluate(MeshTopology mesh);
}

class CurvatureFilter implements RegionFilter {
  const CurvatureFilter(this.minimum);
  final double minimum;
  @override
  String get expression => 'curvature>$minimum';
  @override
  TriangleSelection evaluate(MeshTopology mesh) {
    final selected = <int>[];
    for (var i = 0; i < mesh.triangles.length; i++) {
      final neighbors = mesh.triangleNeighbors[i];
      if (neighbors.any(
        (n) =>
            1 - mesh.triangleNormal(i).dot(mesh.triangleNormal(n)).abs() >
            minimum,
      )) {
        selected.add(i);
      }
    }
    return TriangleSelection(selected);
  }
}

class DominantGeometryFilter implements RegionFilter {
  const DominantGeometryFilter(this.type);
  final String type;
  @override
  String get expression => 'geometry=$type';
  @override
  TriangleSelection evaluate(MeshTopology mesh) {
    if (type == 'all') {
      return TriangleSelection(Iterable.generate(mesh.triangles.length));
    }
    final selected = <int>[];
    for (var i = 0; i < mesh.triangles.length; i++) {
      final n = mesh.triangleNormal(i);
      if (type == 'planes' && n.z.abs() > .95) selected.add(i);
      if (type == 'cylinders' && n.z.abs() < .9) selected.add(i);
    }
    return TriangleSelection(selected);
  }
}
