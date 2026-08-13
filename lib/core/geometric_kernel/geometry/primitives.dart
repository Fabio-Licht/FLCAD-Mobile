import 'dart:math' as math;
import 'vectors.dart';

class Line3 {
  const Line3(this.origin, this.direction) : assert(direction != Vector3.zero);
  final Vector3 origin, direction;
  Vector3 at(double t) => origin + direction.normalized * t;
}

class Ray3 extends Line3 {
  const Ray3(super.origin, super.direction);
}

class Segment3 {
  const Segment3(this.start, this.end);
  final Vector3 start, end;
  double get length => start.distanceTo(end);
  Vector3 at(double t) => start + (end - start) * t.clamp(0, 1).toDouble();
}

class Plane3 {
  const Plane3(this.origin, this.normal);
  final Vector3 origin, normal;
  double signedDistance(Vector3 p) => (p - origin).dot(normal.normalized);
  Vector3 project(Vector3 p) => p - normal.normalized * signedDistance(p);
}

class Triangle3 {
  const Triangle3(this.a, this.b, this.c);
  final Vector3 a, b, c;
  Vector3 get normal => (b - a).cross(c - a).normalized;
  double get area => (b - a).cross(c - a).length / 2;
  Vector3 get centroid => (a + b + c) / 3;
}

class Polygon3 {
  const Polygon3(this.vertices);
  final List<Vector3> vertices;
}

class Polyhedron {
  const Polyhedron(this.vertices, this.faces);
  final List<Vector3> vertices;
  final List<List<int>> faces;
}

class BoundingBox3 {
  const BoundingBox3(this.min, this.max);
  final Vector3 min, max;
  bool contains(Vector3 p) =>
      p.x >= min.x &&
      p.x <= max.x &&
      p.y >= min.y &&
      p.y <= max.y &&
      p.z >= min.z &&
      p.z <= max.z;
  Vector3 get center => (min + max) / 2;
  factory BoundingBox3.fromPoints(Iterable<Vector3> points) {
    final p = points.toList();
    if (p.isEmpty) throw ArgumentError('Points required');
    var min = p.first, max = p.first;
    for (final v in p.skip(1)) {
      min = Vector3(
        math.min(min.x, v.x),
        math.min(min.y, v.y),
        math.min(min.z, v.z),
      );
      max = Vector3(
        math.max(max.x, v.x),
        math.max(max.y, v.y),
        math.max(max.z, v.z),
      );
    }
    return BoundingBox3(min, max);
  }
}

class BoundingSphere {
  const BoundingSphere(this.center, this.radius);
  final Vector3 center;
  final double radius;
  bool contains(Vector3 p) => center.distanceTo(p) <= radius;
}

class OrientedBoundingBox {
  const OrientedBoundingBox(this.center, this.halfExtents, this.axes);
  final Vector3 center, halfExtents;
  final List<Vector3> axes;
}

class Frustum {
  const Frustum(this.planes);
  final List<Plane3> planes;
  bool contains(Vector3 p) =>
      planes.every((plane) => plane.signedDistance(p) >= 0);
}

class CoordinateSystem3 {
  const CoordinateSystem3(this.origin, this.xAxis, this.yAxis, this.zAxis);
  final Vector3 origin, xAxis, yAxis, zAxis;
  factory CoordinateSystem3.world() => const CoordinateSystem3(
    Vector3.zero,
    Vector3(1, 0, 0),
    Vector3(0, 1, 0),
    Vector3(0, 0, 1),
  );
  Vector3 localToGlobal(Vector3 p) =>
      origin + xAxis * p.x + yAxis * p.y + zAxis * p.z;
  Vector3 globalToLocal(Vector3 p) {
    final d = p - origin;
    return Vector3(d.dot(xAxis), d.dot(yAxis), d.dot(zAxis));
  }
}
