import '../geometry/primitives.dart';
import '../geometry/vectors.dart';
import '../precision/precision.dart';

class RobustPredicates {
  const RobustPredicates(this.precision);
  final PrecisionContext precision;
  int orientation2D(Vector2 a, Vector2 b, Vector2 c) {
    final value = (b - a).cross(c - a),
        eps = precision.adaptiveEpsilon([a.x, a.y, b.x, b.y, c.x, c.y]);
    return value.abs() <= eps
        ? 0
        : value > 0
        ? 1
        : -1;
  }

  bool equal(double a, double b) => precision.tolerance.close(a, b);
}

class GeometryAlgorithms {
  const GeometryAlgorithms({this.precision = const PrecisionContext()});
  final PrecisionContext precision;
  double pointLineDistance(Vector3 p, Line3 line) =>
      (p - line.origin).cross(line.direction.normalized).length;
  Vector3 closestPointOnSegment(Vector3 p, Segment3 s) {
    final d = s.end - s.start, t = (p - s.start).dot(d) / d.lengthSquared;
    return s.at(t);
  }

  Vector3 projectOnPlane(Vector3 p, Plane3 plane) => plane.project(p);
  Vector3 barycentric(Vector3 p, Triangle3 t) {
    final v0 = t.b - t.a,
        v1 = t.c - t.a,
        v2 = p - t.a,
        d00 = v0.dot(v0),
        d01 = v0.dot(v1),
        d11 = v1.dot(v1),
        d20 = v2.dot(v0),
        d21 = v2.dot(v1),
        den = d00 * d11 - d01 * d01;
    if (den.abs() <= precision.tolerance.absolute) {
      throw StateError('Degenerate triangle');
    }
    final v = (d11 * d20 - d01 * d21) / den, w = (d00 * d21 - d01 * d20) / den;
    return Vector3(1 - v - w, v, w);
  }

  Vector3? linePlaneIntersection(Line3 line, Plane3 plane) {
    final d = plane.normal.dot(line.direction);
    if (d.abs() <= precision.tolerance.absolute) return null;
    return line.at(plane.normal.dot(plane.origin - line.origin) / d);
  }

  double polygonArea2D(List<Vector2> p) {
    var a = 0.0;
    for (var i = 0; i < p.length; i++) {
      a += p[i].cross(p[(i + 1) % p.length]);
    }
    return a.abs() / 2;
  }

  bool pointInPolygon(Vector2 p, List<Vector2> polygon) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final a = polygon[i], b = polygon[j];
      if ((a.y > p.y) != (b.y > p.y) &&
          p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) {
        inside = !inside;
      }
    }
    return inside;
  }

  double tetrahedronVolume(Vector3 a, Vector3 b, Vector3 c, Vector3 d) =>
      (b - a).dot((c - a).cross(d - a)).abs() / 6;
  Vector3 centroid(Iterable<Vector3> points) {
    final p = points.toList();
    return p.fold<Vector3>(Vector3.zero, (a, b) => a + b) / p.length.toDouble();
  }
}
