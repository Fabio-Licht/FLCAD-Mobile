import 'package:flcad_mobile/core/cad_document/managed_cad_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('managed STL remains a mesh regardless of display metadata', () {
    final identity = ManagedCadIdentity.stl();

    expect(identity.categoryLabel, 'Meshes');
    expect(identity.visualTypeLabel, 'Malha STL');
  });

  test('managed shape category comes from native shape topology, not mesh', () {
    final solid = ManagedCadIdentity.shape(format: 'step', shapeType: 'solid');
    final surface = ManagedCadIdentity.shape(
      format: 'brep',
      shapeType: 'shell',
    );

    expect(solid.categoryLabel, 'Solids');
    expect(solid.visualTypeLabel, 'Sólido STEP');
    expect(surface.categoryLabel, 'Surfaces');
    expect(surface.visualTypeLabel, 'Superfície BREP');
  });

  test('source basename collision has a deterministic suffix', () {
    expect(
      managedCadImportName('MATRIZ INFERIOR', const []),
      'MATRIZ INFERIOR',
    );
    expect(
      managedCadImportName('MATRIZ INFERIOR', const [
        'matriz inferior',
        'MATRIZ INFERIOR (2)',
      ]),
      'MATRIZ INFERIOR (3)',
    );
  });
}
