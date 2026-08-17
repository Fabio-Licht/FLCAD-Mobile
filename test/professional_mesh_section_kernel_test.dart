import 'package:flcad_mobile/app/engineering_bridge/selection/mesh_bvh.dart';
import 'package:flcad_mobile/app/engineering_bridge/selection/mesh_section_kernel.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/primitives.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

const _plane = Plane3(Vector3.zero, Vector3(0, 0, 1));

ProfessionalMeshSectionKernel _kernel(
  List<Vector3> points,
  List<int> triangles, {
  int leafSize = 1,
}) {
  final geometry = KernelMeshGeometry(
    nodes: points.expand((point) => [point.x, point.y, point.z]).toList(),
    triangles: triangles,
  );
  return ProfessionalMeshSectionKernel(MeshBvh(geometry, leafSize: leafSize));
}

void main() {
  group('ProfessionalMeshSectionKernel', () {
    test('returns no candidates when plane misses mesh BVH', () {
      final result = _kernel(
        const [Vector3(0, 0, 2), Vector3(1, 0, 2), Vector3(0, 1, 2)],
        const [0, 1, 2],
      ).intersect(plane: _plane);

      expect(result.diagnostics.candidateTriangles, 0);
      expect(result.diagnostics.processedTriangles, 0);
      expect(result.segments, isEmpty);
    });

    test('creates crossing segment and projects endpoints onto plane', () {
      final result = _kernel(
        const [Vector3(-1, 0, -1), Vector3(1, 0, 1), Vector3(0, 2, 1)],
        const [0, 1, 2],
      ).intersect(plane: _plane);

      expect(result.segments, hasLength(1));
      expect(result.segments.single.topology, SectionSegmentTopology.crossing);
      expect(result.segments.single.a.z, closeTo(0, 1e-15));
      expect(result.segments.single.b.z, closeTo(0, 1e-15));
    });

    test('retains vertex tangency as a point, never a zero segment', () {
      final result = _kernel(
        const [Vector3(0, 0, 0), Vector3(1, 0, 1), Vector3(0, 1, 1)],
        const [0, 1, 2],
      ).intersect(plane: _plane);

      expect(result.segments, isEmpty);
      expect(result.points, hasLength(1));
      expect(result.diagnostics.pointCount, 1);
    });

    test('creates vertex-to-opposite-edge segment', () {
      final result = _kernel(
        const [Vector3(0, 0, 0), Vector3(1, 0, 1), Vector3(0, 1, -1)],
        const [0, 1, 2],
      ).intersect(plane: _plane);

      expect(result.segments, hasLength(1));
      expect(
        result.segments.single.topology,
        SectionSegmentTopology.vertexToEdge,
      );
    });

    test('emits an edge with two vertices on plane exactly once', () {
      final result = _kernel(
        const [
          Vector3(0, 0, 0),
          Vector3(1, 0, 0),
          Vector3(0, 1, 1),
          Vector3(0, -1, -1),
        ],
        const [0, 1, 2, 1, 0, 3],
      ).intersect(plane: _plane);

      expect(result.segments, hasLength(1));
      expect(
        result.segments.single.topology,
        SectionSegmentTopology.coplanarEdge,
      );
    });

    test('full coplanar patch removes internal edge and keeps boundary', () {
      final result = _kernel(
        const [
          Vector3(0, 0, 0),
          Vector3(1, 0, 0),
          Vector3(1, 1, 0),
          Vector3(0, 1, 0),
        ],
        const [0, 1, 2, 0, 2, 3],
      ).intersect(plane: _plane);

      expect(result.diagnostics.coplanarTriangleCount, 2);
      expect(result.segments, hasLength(4));
      expect(
        result.segments.every(
          (segment) =>
              segment.topology == SectionSegmentTopology.coplanarBoundary,
        ),
        isTrue,
      );
    });

    test('uses scalable tolerance for nearly coplanar triangle', () {
      final result =
          _kernel(
            const [
              Vector3(0, 0, 1e-7),
              Vector3(1000, 0, 1e-7),
              Vector3(0, 1000, 1e-7),
            ],
            const [0, 1, 2],
          ).intersect(
            plane: _plane,
            tolerance: const MeshSectionTolerance(
              absolute: 1e-9,
              relative: 1e-9,
            ),
          );

      expect(result.diagnostics.coplanarTriangleCount, 1);
      expect(result.segments, hasLength(3));
      expect(result.segments.first.tolerance, greaterThan(1e-7));
    });

    test('classifies collapsed triangle and reports its tangential point', () {
      final result = _kernel(
        const [Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0)],
        const [0, 1, 2],
      ).intersect(plane: _plane);

      expect(result.diagnostics.degenerateCount, 1);
      expect(result.points, hasLength(1));
      expect(result.segments, isEmpty);
    });

    test('deduplicates repeated STL facets', () {
      final result = _kernel(
        const [
          Vector3(-1, 0, -1),
          Vector3(1, 0, 1),
          Vector3(0, 2, 1),
          Vector3(-1, 0, -1),
          Vector3(1, 0, 1),
          Vector3(0, 2, 1),
        ],
        const [0, 1, 2, 3, 4, 5],
      ).intersect(plane: _plane);

      expect(result.segments, hasLength(1));
    });

    test('diagnoses non-manifold coincident section edge', () {
      final result = _kernel(
        const [
          Vector3(0, 0, 0),
          Vector3(1, 0, 0),
          Vector3(0, 1, 1),
          Vector3(0, -1, 1),
          Vector3(0, 2, 1),
        ],
        const [0, 1, 2, 1, 0, 3, 0, 1, 4],
      ).intersect(plane: _plane);

      expect(result.segments, hasLength(1));
      expect(result.diagnostics.nonManifoldEdgeCount, 1);
    });
  });
}
