import 'package:flcad_mobile/core/professional_fill/professional_fill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Fill accepts an arbitrary number of persistent boundaries and loops',
    () {
      final conditions = List.generate(
        11,
        (index) => FillBoundaryCondition(
          boundaryEntityId: 'Edge${index + 1}',
          boundaryShapeId: 'edge-shape-${index + 1}',
          loopId: index < 7 ? 'outer' : 'inner-1',
        ),
      );
      for (final condition in conditions) {
        expect(condition.validate, returnsNormally);
      }
      expect(conditions.map((item) => item.loopId).toSet(), {
        'outer',
        'inner-1',
      });
    },
  );

  test('each Fill boundary persists independent G0/G1 and influence', () {
    const tangent = FillBoundaryCondition(
      boundaryEntityId: 'Edge001',
      boundaryShapeId: 'edge-shape',
      loopId: 'outer',
      continuity: FillBoundaryContinuity.g1,
      influence: .45,
      supportSurfaceId: 'Surface001',
      supportShapeId: 'face-shape',
    );
    expect(tangent.validate, returnsNormally);
    final restored = FillBoundaryCondition.fromJson(tangent.toJson());
    expect(restored.continuity, FillBoundaryContinuity.g1);
    expect(restored.influence, .45);
    expect(restored.supportSurfaceId, 'Surface001');
  });

  test('Fill rejects unsupported G2 and G1 without support Surface', () {
    expect(
      const FillBoundaryCondition(
        boundaryEntityId: 'Edge001',
        boundaryShapeId: 'edge-shape',
        loopId: 'outer',
        continuity: FillBoundaryContinuity.g2Prepared,
      ).validate,
      throwsUnsupportedError,
    );
    expect(
      const FillBoundaryCondition(
        boundaryEntityId: 'Edge001',
        boundaryShapeId: 'edge-shape',
        loopId: 'outer',
        continuity: FillBoundaryContinuity.g1,
      ).validate,
      throwsArgumentError,
    );
  });

  test('Fill naming is stable and collision-free', () {
    expect(ProfessionalFillNaming.nextId(const []), 'Fill001');
    expect(
      ProfessionalFillNaming.nextId(const ['Fill001', 'Fill003']),
      'Fill002',
    );
  });
}
