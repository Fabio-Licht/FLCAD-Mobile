import 'dart:isolate';
import '../models/geometry.dart';
import '../selection/triangle_selection.dart';

class BackgroundRegionExecutor {
  Future<TriangleSelection> union(TriangleSelection a, TriangleSelection b) =>
      Isolate.run(() => a.union(b));
  Future<TriangleSelection> intersect(
    TriangleSelection a,
    TriangleSelection b,
  ) => Isolate.run(() => a.intersect(b));
  Future<TriangleSelection> subtract(
    TriangleSelection a,
    TriangleSelection b,
  ) => Isolate.run(() => a.subtract(b));
  Future<List<Set<int>>> buildAdjacency(MeshTopology mesh) =>
      Isolate.run(() => mesh.triangleNeighbors);
}
