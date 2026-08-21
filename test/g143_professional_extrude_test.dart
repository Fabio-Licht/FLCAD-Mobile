import 'package:flcad_mobile/core/professional_extrude/professional_extrude.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adapter = ProfessionalExtrudeConstraintAdapter();

  test('Sketch and Surface use the same entity-neutral Solver contract', () {
    for (final kind in ProfessionalExtrudeSourceKind.values) {
      final value = _contract(kind: kind);
      final plan = adapter.solve(value);
      expect(plan.anchor, 'Source001');
      expect(plan.moving, 'extrude.distance');
      expect(adapter.health(value).ready, isTrue);
    }
  });

  test('normal and reverse preserve a positive parametric distance', () {
    final normal = _contract();
    final reverse = _contract(direction: ProfessionalExtrudeDirection.reverse);
    expect(normal.reverse, isFalse);
    expect(reverse.reverse, isTrue);
    expect(reverse.toJson()['distance'], 10);
    expect(
      ProfessionalExtrudeContract.fromJson(reverse.toJson()).direction,
      ProfessionalExtrudeDirection.reverse,
    );
  });

  test('solid and surface outputs persist through the same contract', () {
    for (final output in ProfessionalExtrudeOutput.values) {
      final value = _contract(output: output);
      expect(adapter.health(value).ready, isTrue);
      expect(
        ProfessionalExtrudeContract.fromJson(value.toJson()).output,
        output,
      );
    }
  });

  test('future extents are prepared but cannot execute in G-143', () {
    for (final extent in ProfessionalExtrudeExtent.values.skip(1)) {
      expect(
        () => adapter.solve(_contract(extent: extent)),
        throwsUnsupportedError,
      );
    }
    expect(() => adapter.solve(_contract(distance: 0)), throwsArgumentError);
  });

  test('Extrude identity naming is permanent and collision-free', () {
    expect(ProfessionalExtrudeNaming.nextId(const []), 'Extrude001');
    expect(
      ProfessionalExtrudeNaming.nextId(const ['Extrude001', 'Extrude003']),
      'Extrude002',
    );
  });
}

ProfessionalExtrudeContract _contract({
  ProfessionalExtrudeSourceKind kind = ProfessionalExtrudeSourceKind.sketch,
  ProfessionalExtrudeDirection direction = ProfessionalExtrudeDirection.normal,
  ProfessionalExtrudeExtent extent = ProfessionalExtrudeExtent.distance,
  ProfessionalExtrudeOutput output = ProfessionalExtrudeOutput.solid,
  double distance = 10,
}) => ProfessionalExtrudeContract(
  sourceEntityId: 'Source001',
  sourceKind: kind,
  sourceRevision: 1,
  sourceShapeId: 'profile-shape',
  distance: distance,
  direction: direction,
  extent: extent,
  output: output,
);
