import 'package:flcad_mobile/core/professional_surface_fillet/professional_surface_fillet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProfessionalSurfaceFilletContract contract({
    SurfaceFilletSizeMode mode = SurfaceFilletSizeMode.constantRadius,
    List<SurfaceFilletRadiusPoint> points = const [],
    SurfaceFilletContinuity continuity = SurfaceFilletContinuity.g1,
  }) => ProfessionalSurfaceFilletContract(
    sourceEntityIds: const ['Surface001', 'Surface002'],
    edgeEntityIds: const ['Edge001'],
    selectionMode: SurfaceFilletSelectionMode.edge,
    sizeMode: mode,
    radius: 5,
    width: 8,
    radiusPoints: points,
    continuity: continuity,
  );

  test('constant radius and chordal width are persistent contracts', () {
    for (final mode in [
      SurfaceFilletSizeMode.constantRadius,
      SurfaceFilletSizeMode.constantWidth,
    ]) {
      final value = contract(mode: mode);
      expect(value.validate, returnsNormally);
      expect(
        ProfessionalSurfaceFilletContract.fromJson(value.toJson()).sizeMode,
        mode,
      );
    }
  });

  test('variable radius preserves all interpolation controls', () {
    final value = contract(
      mode: SurfaceFilletSizeMode.variableRadius,
      points: const [
        SurfaceFilletRadiusPoint(0, 2),
        SurfaceFilletRadiusPoint(.45, 5),
        SurfaceFilletRadiusPoint(1, 8),
      ],
    );
    expect(value.validate, returnsNormally);
    final restored = ProfessionalSurfaceFilletContract.fromJson(value.toJson());
    expect(restored.radiusPoints.map((item) => item.value), [2, 5, 8]);
  });

  test('selection modes and compensation remain explicit', () {
    for (final mode in SurfaceFilletSelectionMode.values) {
      final value = ProfessionalSurfaceFilletContract(
        sourceEntityIds: const ['Surface001', 'Surface002'],
        edgeEntityIds: mode == SurfaceFilletSelectionMode.faceToFace
            ? const []
            : const ['Edge001'],
        selectionMode: mode,
        sizeMode: SurfaceFilletSizeMode.constantRadius,
        compensate: true,
        compensationGap: .08,
      );
      expect(value.validate, returnsNormally);
      expect(value.toJson()['compensationGap'], .08);
    }
  });

  test('G2 is prepared but cannot execute', () {
    expect(
      contract(continuity: SurfaceFilletContinuity.g2Prepared).validate,
      throwsUnsupportedError,
    );
  });

  test('Fillet identity naming is stable', () {
    expect(ProfessionalSurfaceFilletNaming.nextId(const []), 'Fillet001');
    expect(
      ProfessionalSurfaceFilletNaming.nextId(const ['Fillet001', 'Fillet003']),
      'Fillet002',
    );
  });
}
