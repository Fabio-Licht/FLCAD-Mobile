import 'package:flcad_mobile/core/surface_operations/models/surface_operation_models.dart';
import 'package:flcad_mobile/core/surface_reduce/constraints/reduce_constraint_solver.dart';
import 'package:flcad_mobile/core/surface_reduce/models/surface_reduce_models.dart';
import 'package:flcad_mobile/core/surface_reduce/runtime/surface_reduce_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('professional suite exposes every certified reduce strategy', () {
    expect(ReduceType.values, hasLength(11));
    expect(
      ReduceType.values,
      containsAll(const [
        ReduceType.radius,
        ReduceType.offset,
        ReduceType.direction,
        ReduceType.untilTarget,
        ReduceType.smart,
        ReduceType.manufacturing,
        ReduceType.feature,
        ReduceType.local,
        ReduceType.global,
        ReduceType.progressive,
        ReduceType.constraintDriven,
      ]),
    );
    expect(
      SurfaceOperationType.values,
      contains(SurfaceOperationType.reduceSurface),
    );
  });

  test('100 constraint validations preserve fixed regions', () {
    const solver = ReduceConstraintSolver();
    for (var i = 0; i < 100; i++) {
      final result = solver.solve(
        [
          SurfaceConstraint(
            id: 'anchor:$i',
            type: SurfaceConstraintType.anchor,
            targetId: 'patch:$i',
          ),
          SurfaceConstraint(
            id: 'tangent:$i',
            type: SurfaceConstraintType.tangency,
            targetId: 'boundary:$i',
          ),
        ],
        [
          FixedRegion(
            id: 'fixed:$i',
            type: FixedRegionType.boundary,
            targetId: 'boundary:$i',
          ),
        ],
      );
      expect(result.valid, isTrue);
      expect(result.conflicts, isEmpty);
    }
  });

  test('conflicting constraints and invalid fixed distance are blocked', () {
    final result = const ReduceConstraintSolver().solve(
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
        FixedRegion(
          id: 'fixed',
          type: FixedRegionType.distance,
          targetId: 'patch',
          distance: -1,
        ),
      ],
    );
    expect(result.valid, isFalse);
    expect(result.conflicts, hasLength(2));
  });

  test('runtime bootstrap is passive and explicit', () async {
    final runtime = SurfaceReduceRuntime.instance;
    await runtime.shutdown();
    expect(runtime.isInitialized, isFalse);
    await runtime.initialize();
    expect(runtime.isInitialized, isTrue);
    await runtime.shutdown();
  });
}
