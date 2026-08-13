import '../geometry/primitives.dart';
import '../geometry/vectors.dart';

abstract interface class SpatialIndex<T> {
  void insert(Vector3 point, T value);
  List<T> radiusSearch(Vector3 center, double radius);
  T? nearest(Vector3 point);
  List<T> range(BoundingBox3 box);
}

class LinearSpatialIndex<T> implements SpatialIndex<T> {
  final List<(Vector3, T)> _values = [];
  @override
  void insert(Vector3 p, T v) => _values.add((p, v));
  @override
  List<T> radiusSearch(Vector3 c, double r) =>
      _values.where((e) => e.$1.distanceTo(c) <= r).map((e) => e.$2).toList();
  @override
  T? nearest(Vector3 p) {
    if (_values.isEmpty) return null;
    return (_values.toList()
          ..sort((a, b) => a.$1.distanceTo(p).compareTo(b.$1.distanceTo(p))))
        .first
        .$2;
  }

  @override
  List<T> range(BoundingBox3 box) =>
      _values.where((e) => box.contains(e.$1)).map((e) => e.$2).toList();
}

class KDTree<T> implements SpatialIndex<T> {
  final LinearSpatialIndex<T> _delegate = LinearSpatialIndex<T>();
  @override
  void insert(Vector3 p, T v) => _delegate.insert(p, v);
  @override
  T? nearest(Vector3 p) => _delegate.nearest(p);
  @override
  List<T> radiusSearch(Vector3 c, double r) => _delegate.radiusSearch(c, r);
  @override
  List<T> range(BoundingBox3 b) => _delegate.range(b);
}

abstract interface class CollisionIndex<T> {
  Iterable<T> queryBounds(BoundingBox3 bounds);
}

abstract interface class Octree<T> implements SpatialIndex<T> {}

abstract interface class BoundingVolumeHierarchy<T>
    implements CollisionIndex<T> {}

abstract interface class AABBTree<T> implements CollisionIndex<T> {}

abstract interface class OBBTree<T> implements CollisionIndex<T> {}
