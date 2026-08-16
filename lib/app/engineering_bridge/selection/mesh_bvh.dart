import 'dart:math' as math;

import '../../../core/cad_kernel/io/kernel_io_models.dart';
import '../../../core/geometric_kernel/geometry/vectors.dart';
import '../contracts/bridge_selection.dart';

class MeshBvh {
  MeshBvh(KernelMeshGeometry geometry, {this.leafSize = 8})
    : _geometry = geometry,
      root = _build(
        geometry,
        List.generate(geometry.triangles.length ~/ 3, (i) => i),
        leafSize,
      );
  final KernelMeshGeometry _geometry;
  final int leafSize;
  final MeshBvhNode root;

  Set<int> query(MeshRay ray) {
    final result = <int>{};
    void visit(MeshBvhNode node) {
      if (!_intersects(node.bounds, ray)) return;
      if (node.triangles != null) {
        result.addAll(node.triangles!);
      } else {
        visit(node.left!);
        visit(node.right!);
      }
    }

    visit(root);
    return result;
  }

  BridgeSelection candidates(BridgeSelection source, MeshRay ray) {
    final found = query(ray).intersection(source.triangleIndices);
    return BridgeSelection(
      id: source.id,
      kind: source.kind,
      geometry: _geometry,
      triangleIndices: found,
      entityId: source.entityId,
    );
  }

  static MeshBvhNode _build(
    KernelMeshGeometry geometry,
    List<int> ids,
    int leafSize,
  ) {
    if (ids.isEmpty) {
      throw ArgumentError('BVH requires at least one triangle.');
    }
    final bounds = _boundsFor(geometry, ids);
    if (ids.length <= leafSize) {
      return MeshBvhNode(bounds: bounds, triangles: List.unmodifiable(ids));
    }
    final extents = [
      bounds.max.x - bounds.min.x,
      bounds.max.y - bounds.min.y,
      bounds.max.z - bounds.min.z,
    ];
    var axis = 0;
    if (extents[1] > extents[axis]) axis = 1;
    if (extents[2] > extents[axis]) axis = 2;
    ids.sort(
      (a, b) =>
          _centroid(geometry, a, axis).compareTo(_centroid(geometry, b, axis)),
    );
    final middle = ids.length ~/ 2;
    return MeshBvhNode(
      bounds: bounds,
      left: _build(geometry, ids.sublist(0, middle), leafSize),
      right: _build(geometry, ids.sublist(middle), leafSize),
    );
  }

  static double _centroid(KernelMeshGeometry geometry, int triangle, int axis) {
    final offset = triangle * 3;
    var total = 0.0;
    for (var i = 0; i < 3; i++) {
      total += geometry.nodes[geometry.triangles[offset + i] * 3 + axis];
    }
    return total / 3;
  }

  static MeshBvhBounds _boundsFor(KernelMeshGeometry geometry, List<int> ids) {
    var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    var maxX = double.negativeInfinity,
        maxY = double.negativeInfinity,
        maxZ = double.negativeInfinity;
    for (final triangle in ids) {
      final offset = triangle * 3;
      for (var i = 0; i < 3; i++) {
        final vertex = geometry.triangles[offset + i] * 3;
        final x = geometry.nodes[vertex],
            y = geometry.nodes[vertex + 1],
            z = geometry.nodes[vertex + 2];
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        minZ = math.min(minZ, z);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
        maxZ = math.max(maxZ, z);
      }
    }
    return MeshBvhBounds(Vector3(minX, minY, minZ), Vector3(maxX, maxY, maxZ));
  }

  static bool _intersects(MeshBvhBounds bounds, MeshRay ray) {
    var near = double.negativeInfinity, far = double.infinity;
    for (var axis = 0; axis < 3; axis++) {
      final origin = [ray.origin.x, ray.origin.y, ray.origin.z][axis];
      final direction = [
        ray.direction.x,
        ray.direction.y,
        ray.direction.z,
      ][axis];
      final minimum = [bounds.min.x, bounds.min.y, bounds.min.z][axis];
      final maximum = [bounds.max.x, bounds.max.y, bounds.max.z][axis];
      if (direction.abs() < 1e-12) {
        if (origin < minimum || origin > maximum) return false;
        continue;
      }
      var first = (minimum - origin) / direction,
          second = (maximum - origin) / direction;
      if (first > second) {
        final swap = first;
        first = second;
        second = swap;
      }
      near = math.max(near, first);
      far = math.min(far, second);
      if (near > far) return false;
    }
    return far >= math.max(near, 0);
  }
}

class MeshBvhNode {
  const MeshBvhNode({
    required this.bounds,
    this.triangles,
    this.left,
    this.right,
  });
  final MeshBvhBounds bounds;
  final List<int>? triangles;
  final MeshBvhNode? left, right;
}

class MeshBvhBounds {
  const MeshBvhBounds(this.min, this.max);
  final Vector3 min, max;
}
