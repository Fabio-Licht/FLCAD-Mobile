import 'package:flcad_mobile/core/surface_boundary/constraints/boundary_constraint_solver.dart';
import 'package:flcad_mobile/core/surface_boundary/models/surface_boundary_models.dart';
import 'package:flcad_mobile/core/surface_boundary/runtime/surface_boundary_runtime.dart';
import 'package:flcad_mobile/core/surface_operations/models/surface_operation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('professional suite exposes all eleven boundary strategies', () {
    expect(BoundaryOperationType.values, hasLength(11));
    expect(
      SurfaceOperationType.values,
      contains(SurfaceOperationType.editBoundary),
    );
  });

  test('100 boundary analyses and previews remain non-mutating', () {
    for (var i = 0; i < 100; i++) {
      const analysis = BoundaryAnalysis(
        originalLength: 10,
        predictedLength: 10.5,
        continuity: BoundaryContinuity.g2,
        curvature: .9,
        stress: .1,
        twist: .1,
        quality: .9,
        manufacturingScore: .85,
      );
      const preview = BoundaryPreview(
        newPosition: [0, 0, .5],
        reflection: .9,
        zebra: .9,
        heatMap: {'boundary:a': .1},
        analysis: analysis,
        affectedRegions: ['boundary:a', 'patch:a'],
      );
      expect(preview.toJson()['geometryModified'], isFalse);
      expect(analysis.toJson()['lengthChange'], .5);
    }
  });

  test('100 boundary constraint validations preserve protected regions', () {
    const solver = BoundaryConstraintSolver();
    for (var i = 0; i < 100; i++) {
      final result = solver.solve(
        [
          SurfaceConstraint(
            id: 't:$i',
            type: SurfaceConstraintType.tangency,
            targetId: 'boundary:$i',
          ),
        ],
        [
          BoundaryFixedRegion(
            id: 'p:$i',
            type: BoundaryFixedRegionType.patch,
            targetId: 'patch:$i',
          ),
        ],
        'boundary:$i',
      );
      expect(result.valid, isTrue);
    }
  });

  test('editing a fixed boundary is blocked', () {
    final result = const BoundaryConstraintSolver().solve(const [], const [
      BoundaryFixedRegion(
        id: 'fixed',
        type: BoundaryFixedRegionType.boundary,
        targetId: 'boundary:a',
      ),
    ], 'boundary:a');
    expect(result.valid, isFalse);
  });

  test('runtime bootstrap is passive and explicit', () async {
    final runtime = SurfaceBoundaryRuntime.instance;
    await runtime.shutdown();
    expect(runtime.isInitialized, isFalse);
    await runtime.initialize();
    expect(runtime.isInitialized, isTrue);
    await runtime.shutdown();
  });
}
