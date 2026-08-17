import 'dart:math' as math;

import '../../../core/geometric_kernel/geometry/primitives.dart';
import '../../../core/geometric_kernel/geometry/vectors.dart';
import 'mesh_bvh.dart';

enum SectionSegmentTopology {
  crossing,
  vertexToEdge,
  coplanarEdge,
  coplanarBoundary,
  degenerate,
}

class SectionSegment {
  const SectionSegment({
    required this.a,
    required this.b,
    required this.sourceTriangle,
    required this.sourceEdges,
    required this.topology,
    required this.tolerance,
  });

  final Vector3 a, b;
  final int sourceTriangle;
  final List<int> sourceEdges;
  final SectionSegmentTopology topology;
  final double tolerance;
}

class MeshSectionTolerance {
  const MeshSectionTolerance({this.absolute = 1e-9, this.relative = 1e-10})
    : assert(absolute >= 0),
      assert(relative >= 0);

  final double absolute, relative;

  double resolve(MeshBvhBounds bounds) {
    final diagonal = (bounds.max - bounds.min).length;
    return math.max(absolute, relative * math.max(diagonal, 1));
  }
}

class MeshSectionDiagnostics {
  const MeshSectionDiagnostics({
    required this.candidateTriangles,
    required this.processedTriangles,
    required this.segmentCount,
    required this.pointCount,
    required this.degenerateCount,
    required this.coplanarTriangleCount,
    required this.nonManifoldEdgeCount,
    required this.elapsed,
  });

  final int candidateTriangles;
  final int processedTriangles;
  final int segmentCount;
  final int pointCount;
  final int degenerateCount;
  final int coplanarTriangleCount;
  final int nonManifoldEdgeCount;
  final Duration elapsed;
}

class MeshSectionResult {
  const MeshSectionResult({
    required this.segments,
    required this.points,
    required this.diagnostics,
  });

  final List<SectionSegment> segments;
  final List<Vector3> points;
  final MeshSectionDiagnostics diagnostics;
}

/// Plane/triangle contouring over candidates from the official mesh BVH.
///
/// This kernel deliberately stops at independent segments. Connectivity,
/// polylines and loops belong to the following section-processing stage.
class ProfessionalMeshSectionKernel {
  const ProfessionalMeshSectionKernel(this.bvh);

  final MeshBvh bvh;

  MeshSectionResult intersect({
    required Plane3 plane,
    MeshSectionTolerance tolerance = const MeshSectionTolerance(),
  }) {
    final watch = Stopwatch()..start();
    final normal = plane.normal.normalized;
    if (normal.lengthSquared == 0 || !_finite(normal)) {
      throw ArgumentError.value(plane.normal, 'plane.normal', 'Invalid normal');
    }
    if (!_finite(plane.origin)) {
      throw ArgumentError.value(plane.origin, 'plane.origin', 'Invalid origin');
    }
    final geometry = bvh.geometry;
    _validateGeometry(geometry.nodes, geometry.triangles);
    final resolvedTolerance = tolerance.resolve(bvh.root.bounds);
    final candidates =
        bvh
            .queryPlane(
              origin: plane.origin,
              normal: normal,
              tolerance: resolvedTolerance,
            )
            .toList()
          ..sort();
    final raw = <_RawSegment>[];
    final tangentPoints = <Vector3>[];
    var degenerates = 0, coplanarTriangles = 0;

    for (final triangleId in candidates) {
      final offset = triangleId * 3;
      final vertexIds = <int>[
        geometry.triangles[offset],
        geometry.triangles[offset + 1],
        geometry.triangles[offset + 2],
      ];
      final vertices = vertexIds
          .map((id) => _point(geometry.nodes, id))
          .toList();
      final area2 = (vertices[1] - vertices[0])
          .cross(vertices[2] - vertices[0])
          .length;
      if (area2 <= resolvedTolerance * resolvedTolerance) {
        degenerates++;
        _intersectDegenerate(
          triangleId,
          vertexIds,
          vertices,
          plane.origin,
          normal,
          resolvedTolerance,
          raw,
          tangentPoints,
        );
        continue;
      }
      final distances = vertices
          .map((point) => _filteredDistance(point, plane.origin, normal))
          .toList();
      final signs = distances
          .map((value) => _sign(value, resolvedTolerance))
          .toList();
      final onPlane = signs.where((value) => value == 0).length;
      if (onPlane == 3) {
        coplanarTriangles++;
        for (var edge = 0; edge < 3; edge++) {
          final next = (edge + 1) % 3;
          raw.add(
            _RawSegment(
              a: _project(vertices[edge], plane.origin, normal),
              b: _project(vertices[next], plane.origin, normal),
              sourceTriangle: triangleId,
              sourceEdges: [edge],
              topology: SectionSegmentTopology.coplanarBoundary,
              coplanarFaceEdge: true,
              third: vertices[(edge + 2) % 3],
            ),
          );
        }
        continue;
      }
      if (onPlane == 2) {
        final ids = <int>[];
        for (var i = 0; i < 3; i++) {
          if (signs[i] == 0) ids.add(i);
        }
        raw.add(
          _RawSegment(
            a: _project(vertices[ids[0]], plane.origin, normal),
            b: _project(vertices[ids[1]], plane.origin, normal),
            sourceTriangle: triangleId,
            sourceEdges: [_edgeIndex(ids[0], ids[1])],
            topology: SectionSegmentTopology.coplanarEdge,
          ),
        );
        continue;
      }
      if (onPlane == 1) {
        final on = signs.indexOf(0);
        final other = <int>[0, 1, 2]..remove(on);
        if (signs[other[0]] == signs[other[1]]) {
          tangentPoints.add(_project(vertices[on], plane.origin, normal));
        } else {
          raw.add(
            _RawSegment(
              a: _project(vertices[on], plane.origin, normal),
              b: _edgeIntersection(
                vertices[other[0]],
                vertices[other[1]],
                distances[other[0]],
                distances[other[1]],
                plane.origin,
                normal,
              ),
              sourceTriangle: triangleId,
              sourceEdges: [_edgeIndex(other[0], other[1])],
              topology: SectionSegmentTopology.vertexToEdge,
            ),
          );
        }
        continue;
      }
      if (signs.every((value) => value == signs.first)) continue;
      final intersections = <Vector3>[];
      final intersectedEdges = <int>[];
      for (var edge = 0; edge < 3; edge++) {
        final next = (edge + 1) % 3;
        if (signs[edge] != signs[next]) {
          intersections.add(
            _edgeIntersection(
              vertices[edge],
              vertices[next],
              distances[edge],
              distances[next],
              plane.origin,
              normal,
            ),
          );
          intersectedEdges.add(edge);
        }
      }
      if (intersections.length == 2) {
        raw.add(
          _RawSegment(
            a: intersections[0],
            b: intersections[1],
            sourceTriangle: triangleId,
            sourceEdges: intersectedEdges,
            topology: SectionSegmentTopology.crossing,
          ),
        );
      }
    }

    final consolidated = _consolidate(raw, resolvedTolerance, normal);
    final points = _uniquePoints(tangentPoints, resolvedTolerance);
    watch.stop();
    return MeshSectionResult(
      segments: consolidated.segments,
      points: points,
      diagnostics: MeshSectionDiagnostics(
        candidateTriangles: candidates.length,
        processedTriangles: candidates.length,
        segmentCount: consolidated.segments.length,
        pointCount: points.length,
        degenerateCount: degenerates,
        coplanarTriangleCount: coplanarTriangles,
        nonManifoldEdgeCount: consolidated.nonManifoldEdges,
        elapsed: watch.elapsed,
      ),
    );
  }

  static void _intersectDegenerate(
    int triangleId,
    List<int> vertexIds,
    List<Vector3> vertices,
    Vector3 origin,
    Vector3 normal,
    double tolerance,
    List<_RawSegment> segments,
    List<Vector3> points,
  ) {
    var first = 0, second = 1, longest = -1.0;
    for (final pair in const [(0, 1), (1, 2), (2, 0)]) {
      final length = vertices[pair.$1].distanceTo(vertices[pair.$2]);
      if (length > longest) {
        longest = length;
        first = pair.$1;
        second = pair.$2;
      }
    }
    final da = _filteredDistance(vertices[first], origin, normal);
    final db = _filteredDistance(vertices[second], origin, normal);
    final sa = _sign(da, tolerance), sb = _sign(db, tolerance);
    if (longest <= tolerance) {
      if (sa == 0) points.add(_project(vertices[first], origin, normal));
    } else if (sa == 0 && sb == 0) {
      segments.add(
        _RawSegment(
          a: _project(vertices[first], origin, normal),
          b: _project(vertices[second], origin, normal),
          sourceTriangle: triangleId,
          sourceEdges: [_edgeIndex(first, second)],
          topology: SectionSegmentTopology.degenerate,
        ),
      );
    } else if (sa == 0) {
      points.add(_project(vertices[first], origin, normal));
    } else if (sb == 0) {
      points.add(_project(vertices[second], origin, normal));
    } else if (sa != sb) {
      points.add(
        _edgeIntersection(
          vertices[first],
          vertices[second],
          da,
          db,
          origin,
          normal,
        ),
      );
    }
  }

  static _Consolidated _consolidate(
    List<_RawSegment> raw,
    double tolerance,
    Vector3 normal,
  ) {
    final groups = <String, List<_RawSegment>>{};
    for (final segment in raw) {
      if (segment.a.distanceTo(segment.b) <= tolerance) continue;
      (groups[_segmentKey(segment.a, segment.b, tolerance)] ??= []).add(
        segment,
      );
    }
    final result = <SectionSegment>[];
    var nonManifold = 0;
    for (final group in groups.values) {
      final coplanar = group.where((item) => item.coplanarFaceEdge).toList();
      if (group.length > 2) nonManifold++;
      if (coplanar.length >= 2 && _straddlesEdge(coplanar, normal, tolerance)) {
        continue;
      }
      final selected = group.reduce(
        (a, b) => a.sourceTriangle <= b.sourceTriangle ? a : b,
      );
      var a = selected.a, b = selected.b;
      if (_pointKey(a, tolerance).compareTo(_pointKey(b, tolerance)) > 0) {
        final swap = a;
        a = b;
        b = swap;
      }
      result.add(
        SectionSegment(
          a: a,
          b: b,
          sourceTriangle: selected.sourceTriangle,
          sourceEdges: List.unmodifiable(selected.sourceEdges),
          topology: selected.topology,
          tolerance: tolerance,
        ),
      );
    }
    return _Consolidated(List.unmodifiable(result), nonManifold);
  }

  static bool _straddlesEdge(
    List<_RawSegment> edges,
    Vector3 normal,
    double tolerance,
  ) {
    final edge = edges.first.b - edges.first.a;
    var positive = false, negative = false;
    for (final item in edges) {
      final third = item.third;
      if (third == null) continue;
      final side = edge.cross(third - item.a).dot(normal);
      if (side > tolerance) positive = true;
      if (side < -tolerance) negative = true;
    }
    return positive && negative;
  }

  static List<Vector3> _uniquePoints(List<Vector3> input, double tolerance) {
    final values = <String, Vector3>{};
    for (final point in input) {
      values.putIfAbsent(_pointKey(point, tolerance), () => point);
    }
    return List.unmodifiable(values.values);
  }

  static double _filteredDistance(
    Vector3 point,
    Vector3 origin,
    Vector3 normal,
  ) {
    final x = (point.x - origin.x) * normal.x;
    final y = (point.y - origin.y) * normal.y;
    final z = (point.z - origin.z) * normal.z;
    final fast = x + y + z;
    // Standard floating-point filter: accept an unambiguous fast result and
    // use compensated summation only inside its conservative roundoff bound.
    const machineEpsilon = 2.220446049250313e-16;
    final errorBound = 8 * machineEpsilon * (x.abs() + y.abs() + z.abs());
    if (fast.abs() > errorBound) return fast;
    final values = <double>[x, y, z]
      ..sort((a, b) => a.abs().compareTo(b.abs()));
    var sum = 0.0, compensation = 0.0;
    for (final value in values) {
      final adjusted = value - compensation;
      final next = sum + adjusted;
      compensation = (next - sum) - adjusted;
      sum = next;
    }
    return sum;
  }

  static Vector3 _edgeIntersection(
    Vector3 a,
    Vector3 b,
    double da,
    double db,
    Vector3 origin,
    Vector3 normal,
  ) {
    final denominator = da - db;
    final t = denominator == 0 ? .5 : (da / denominator).clamp(0.0, 1.0);
    return _project(a + (b - a) * t, origin, normal);
  }

  static Vector3 _project(Vector3 point, Vector3 origin, Vector3 normal) =>
      point - normal * normal.dot(point - origin);

  static int _sign(double distance, double tolerance) =>
      distance > tolerance ? 1 : (distance < -tolerance ? -1 : 0);

  static int _edgeIndex(int first, int second) {
    final low = math.min(first, second), high = math.max(first, second);
    if (low == 0 && high == 1) return 0;
    if (low == 1 && high == 2) return 1;
    return 2;
  }

  static Vector3 _point(List<double> nodes, int id) {
    final offset = id * 3;
    return Vector3(nodes[offset], nodes[offset + 1], nodes[offset + 2]);
  }

  static String _segmentKey(Vector3 a, Vector3 b, double tolerance) {
    final first = _pointKey(a, tolerance), second = _pointKey(b, tolerance);
    return first.compareTo(second) <= 0 ? '$first|$second' : '$second|$first';
  }

  static String _pointKey(Vector3 point, double tolerance) {
    final quantum = tolerance > 0 ? tolerance : 1e-15;
    return '${(point.x / quantum).round()}:${(point.y / quantum).round()}:${(point.z / quantum).round()}';
  }

  static bool _finite(Vector3 value) =>
      value.x.isFinite && value.y.isFinite && value.z.isFinite;

  static void _validateGeometry(List<double> nodes, List<int> triangles) {
    if (nodes.length % 3 != 0 ||
        triangles.length % 3 != 0 ||
        triangles.isEmpty) {
      throw ArgumentError('Invalid indexed triangle geometry.');
    }
    final count = nodes.length ~/ 3;
    for (final index in triangles) {
      if (index < 0 || index >= count) {
        throw RangeError('Invalid vertex index $index.');
      }
    }
  }
}

class _RawSegment {
  const _RawSegment({
    required this.a,
    required this.b,
    required this.sourceTriangle,
    this.sourceEdges = const [],
    required this.topology,
    this.coplanarFaceEdge = false,
    this.third,
  });
  final Vector3 a, b;
  final int sourceTriangle;
  final List<int> sourceEdges;
  final SectionSegmentTopology topology;
  final bool coplanarFaceEdge;
  final Vector3? third;
}

class _Consolidated {
  const _Consolidated(this.segments, this.nonManifoldEdges);
  final List<SectionSegment> segments;
  final int nonManifoldEdges;
}
