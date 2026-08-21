import 'package:flcad_mobile/core/professional_revolve/professional_revolve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adapter = ProfessionalRevolveConstraintAdapter();

  test('Sketch and Surface profiles share the abstract Solver contract', () {
    for (final profile in RevolveProfileKind.values) {
      final value = _contract(
        profileKind: profile,
        output: profile == RevolveProfileKind.sketch
            ? RevolveOutput.solid
            : RevolveOutput.surface,
      );
      final plan = adapter.solve(value);
      expect(plan.anchor, 'Profile001');
      expect(plan.moving, 'Axis001');
      expect(adapter.health(value).ready, isTrue);
    }
  });

  test(
    'full, partial, clockwise and counter-clockwise angles are parametric',
    () {
      expect(_contract().signedAngle, 360);
      expect(_contract(angle: 125).signedAngle, 125);
      expect(
        _contract(angle: 90, direction: RevolveDirection.clockwise).signedAngle,
        -90,
      );
      final restored = ProfessionalRevolveContract.fromJson(
        _contract(angle: 45).toJson(),
      );
      expect(restored.angleDegrees, 45);
    },
  );

  test('invalid angles and future axis kinds are rejected', () {
    expect(() => adapter.solve(_contract(angle: 0)), throwsArgumentError);
    expect(() => adapter.solve(_contract(angle: 361)), throwsArgumentError);
    for (final kind in [
      RevolveAxisKind.edgePrepared,
      RevolveAxisKind.recognizedCylinderPrepared,
      RevolveAxisKind.arbitraryPrepared,
    ]) {
      expect(
        () => adapter.solve(_contract(axisKind: kind)),
        throwsUnsupportedError,
      );
    }
  });

  test('Revolve identity naming is stable and collision-free', () {
    expect(ProfessionalRevolveNaming.nextId(const []), 'Revolve001');
    expect(
      ProfessionalRevolveNaming.nextId(const ['Revolve001', 'Revolve003']),
      'Revolve002',
    );
  });
}

ProfessionalRevolveContract _contract({
  RevolveProfileKind profileKind = RevolveProfileKind.sketch,
  RevolveAxisKind axisKind = RevolveAxisKind.referenceAxis,
  RevolveDirection direction = RevolveDirection.counterClockwise,
  RevolveOutput output = RevolveOutput.solid,
  double angle = 360,
}) => ProfessionalRevolveContract(
  profileEntityId: 'Profile001',
  profileKind: profileKind,
  profileRevision: 1,
  profileShapeId: 'profile-shape',
  axisEntityId: 'Axis001',
  axisKind: axisKind,
  axisRevision: 1,
  axisShapeId: 'axis-shape',
  angleDegrees: angle,
  direction: direction,
  output: output,
);
