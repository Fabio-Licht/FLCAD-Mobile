import 'package:flcad_mobile/core/surface_fair/constraints/fair_constraint_solver.dart';
import 'package:flcad_mobile/core/surface_fair/models/surface_fair_models.dart';
import 'package:flcad_mobile/core/surface_fair/runtime/surface_fair_runtime.dart';
import 'package:flcad_mobile/core/surface_operations/models/surface_operation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('professional suite exposes all eleven fair strategies', () {
    expect(FairType.values, hasLength(11));
    expect(
      SurfaceOperationType.values,
      contains(SurfaceOperationType.fairSurface),
    );
  });

  test('100 Reflection and Zebra preview records remain non-mutating', () {
    for (var i = 0; i < 100; i++) {
      const prediction = FairPrediction(
        affectedRegions: ['patch:a'],
        surfaceEnergy: .7,
        reflection: .9,
        zebra: .9,
        curvature: .9,
        heatMap: {'patch:a': .2},
        stress: .2,
        twist: .1,
        distortion: .1,
        quality: .9,
        manufacturingScore: .85,
      );
      expect(prediction.toJson()['predictedReflection'], .9);
      expect(prediction.toJson()['predictedZebra'], .9);
      expect(prediction.toJson()['geometryModified'], isFalse);
    }
  });

  test('100 fixed-region constraint validations pass', () {
    const solver = FairConstraintSolver();
    for (var i = 0; i < 100; i++) {
      final result = solver.solve(
        [
          SurfaceConstraint(
            id: 'tangent:$i',
            type: SurfaceConstraintType.tangency,
            targetId: 'boundary:$i',
          ),
        ],
        [
          FairFixedRegion(
            id: 'fixed:$i',
            type: FairFixedRegionType.boundary,
            targetId: 'boundary:$i',
          ),
        ],
      );
      expect(result.valid, isTrue);
    }
  });

  test('constraint conflicts and invalid fixed radius are blocked', () {
    final result = const FairConstraintSolver().solve(
      const [
        SurfaceConstraint(
          id: 'a',
          type: SurfaceConstraintType.tangency,
          targetId: 'edge',
        ),
        SurfaceConstraint(
          id: 'b',
          type: SurfaceConstraintType.curvature,
          targetId: 'edge',
        ),
      ],
      const [
        FairFixedRegion(
          id: 'radius',
          type: FairFixedRegionType.radius,
          targetId: 'patch',
          radius: 0,
        ),
      ],
    );
    expect(result.valid, isFalse);
    expect(result.conflicts, hasLength(2));
  });

  test('runtime bootstrap remains passive and explicit', () async {
    final runtime = SurfaceFairRuntime.instance;
    await runtime.shutdown();
    expect(runtime.isInitialized, isFalse);
    await runtime.initialize();
    expect(runtime.isInitialized, isTrue);
    await runtime.shutdown();
  });
}
