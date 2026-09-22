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

  test('draft angle persists and validates the executable range', () {
    final drafted = _contract(draftAngleDegrees: 7.5);
    expect(
      ProfessionalExtrudeContract.fromJson(drafted.toJson()).draftAngleDegrees,
      7.5,
    );
    expect(adapter.health(drafted).ready, isTrue);
    expect(
      () => adapter.solve(_contract(draftAngleDegrees: 89)),
      throwsArgumentError,
    );
    expect(
      () => adapter.solve(_contract(draftAngleDegrees: double.nan)),
      throwsArgumentError,
    );
  });

  test(
    'Draft kernel diagnostics distinguish topology failure from no Draft',
    () {
      expect(
        ProfessionalExtrudeConstraintAdapter.diagnosticForKernelFailure(
          StateError('Draft angle could not be applied to the side faces'),
          draftAngleDegrees: 5,
        ),
        contains('topologia deste perfil'),
      );
      expect(
        ProfessionalExtrudeConstraintAdapter.diagnosticForKernelFailure(
          ArgumentError('Extrude draft angle must be finite'),
          draftAngleDegrees: 90,
        ),
        contains('Valor de Draft inválido'),
      );
      expect(
        ProfessionalExtrudeConstraintAdapter.diagnosticForKernelFailure(
          StateError('Extrude builder did not complete'),
          draftAngleDegrees: 0,
        ),
        'Extrude builder did not complete',
      );
    },
  );

  test('selected extrusion axis persists as a real direction vector', () {
    final value = ProfessionalExtrudeContract(
      sourceEntityId: 'Source001',
      sourceKind: ProfessionalExtrudeSourceKind.sketch,
      sourceRevision: 1,
      sourceShapeId: 'profile-shape',
      distance: 10,
      directionSourceId: 'worldX',
      directionVector: const [1, 0, 0],
    );
    final restored = ProfessionalExtrudeContract.fromJson(value.toJson());
    expect(restored.directionSourceId, 'worldX');
    expect(restored.directionVector, [1, 0, 0]);
    expect(adapter.health(restored).ready, isTrue);
  });

  test(
    'selected Sketch profile persists without breaking legacy contracts',
    () {
      final selected = ProfessionalExtrudeContract(
        sourceEntityId: 'Sketch001',
        sourceKind: ProfessionalExtrudeSourceKind.sketch,
        sourceRevision: 2,
        sourceShapeId: 'profile-shape',
        profileEntityId: 'ske:circle-1',
        distance: 10,
      );
      expect(
        ProfessionalExtrudeContract.fromJson(selected.toJson()).profileEntityId,
        'ske:circle-1',
      );
      expect(
        ProfessionalExtrudeContract.fromJson(
          _contract().toJson(),
        ).profileEntityId,
        isNull,
      );
    },
  );

  test('symmetric extent persists and future extents remain blocked', () {
    final symmetric = _contract(extent: ProfessionalExtrudeExtent.symmetric);
    expect(adapter.health(symmetric).ready, isTrue);
    expect(
      ProfessionalExtrudeContract.fromJson(symmetric.toJson()).extent,
      ProfessionalExtrudeExtent.symmetric,
    );
    expect(symmetric.toJson()['symmetricSupported'], isTrue);
    for (final extent in [
      ProfessionalExtrudeExtent.throughAllPrepared,
      ProfessionalExtrudeExtent.upToSurfacePrepared,
    ]) {
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
  double draftAngleDegrees = 0,
}) => ProfessionalExtrudeContract(
  sourceEntityId: 'Source001',
  sourceKind: kind,
  sourceRevision: 1,
  sourceShapeId: 'profile-shape',
  distance: distance,
  draftAngleDegrees: draftAngleDegrees,
  direction: direction,
  extent: extent,
  output: output,
);
