import '../engine/smart_border_engine.dart';
import '../models/geometry.dart';
import '../selection/triangle_selection.dart';

abstract interface class RegionRule {
  String get id;
  TriangleSelection apply(MeshTopology mesh, TriangleSelection input);
  Map<String, dynamic> toJson();
}

class BorderShrinkRule implements RegionRule {
  const BorderShrinkRule(this.rings);
  final int rings;
  @override
  String get id => 'border_shrink';
  @override
  TriangleSelection apply(MeshTopology mesh, TriangleSelection input) =>
      const SmartBorderEngine().shrink(mesh, input, rings: rings);
  @override
  Map<String, dynamic> toJson() => {'id': id, 'rings': rings};
}

class RemoveIslandsRule implements RegionRule {
  const RemoveIslandsRule(this.minimumTriangles);
  final int minimumTriangles;
  @override
  String get id => 'remove_islands';
  @override
  TriangleSelection apply(MeshTopology mesh, TriangleSelection input) {
    final remaining = <int>{...input.indices}, kept = <int>{};
    while (remaining.isNotEmpty) {
      final component = <int>{}, queue = <int>[remaining.first];
      while (queue.isNotEmpty) {
        final v = queue.removeLast();
        if (!remaining.remove(v)) continue;
        component.add(v);
        queue.addAll(mesh.triangleNeighbors[v].where(input.contains));
      }
      if (component.length >= minimumTriangles) kept.addAll(component);
    }
    return TriangleSelection(kept);
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'minimumTriangles': minimumTriangles,
  };
}
