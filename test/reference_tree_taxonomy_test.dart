import 'dart:convert';

import 'package:flcad_mobile/app/desktop/reference_tree_taxonomy.dart';
import 'package:flcad_mobile/app/runtime/world_coordinate_system.dart';
import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/cad_document/managed_cad_reference.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

CadDocumentEntity _entity(
  String id,
  CadDocumentEntityKind kind,
  Map<String, dynamic> data,
) => CadDocumentEntity(id: id, kind: kind, data: data);

void main() {
  const plane = ManagedCadReference.plane(
    sourceEntityId: 'managed-step:part',
    sourceFormat: 'step',
    sourceShapeSha256: _hash,
    faceIndex: 4,
    origin: Vector3(1, 2, 3),
    normal: Vector3(0, 0, 1),
    xDirection: Vector3(1, 0, 0),
  );
  const axis = ManagedCadReference.cylindricalAxis(
    sourceEntityId: 'managed-brep:cylinder',
    sourceFormat: 'brep',
    sourceShapeSha256: _hash,
    faceIndex: 7,
    origin: Vector3(1, 2, 3),
    direction: Vector3(0, 0, 1),
    radius: 8,
  );

  CadDocumentEntity managedPlane() =>
      _entity('reference:plane', CadDocumentEntityKind.reference, {
        'name': 'Plano da face',
        'collectionId': 'collection:references',
        'sceneKind': 'plane',
        ManagedCadReference.dataKey: plane.toJson(),
      });

  CadDocumentEntity managedAxis() =>
      _entity('reference:axis', CadDocumentEntityKind.reference, {
        'name': 'Eixo da face',
        'collectionId': 'collection:references',
        'sceneKind': 'axis',
        ManagedCadReference.dataKey: axis.toJson(),
      });

  test(
    'projects references by final semantic type with stable system order',
    () {
      final system = WorldCoordinateSystem.entities('project').values;
      final point = _entity('point:manual', CadDocumentEntityKind.vertex, {
        'name': 'Ponto manual',
        'collectionId': 'collection:references',
        'constructionEntity': {'type': 'point'},
        'sceneKind': 'point',
      });
      final vector = _entity('vector:manual', CadDocumentEntityKind.reference, {
        'name': 'Vetor manual',
        'collectionId': 'collection:references',
        'constructionEntity': {'type': 'vector'},
        'sceneKind': 'axis',
      });
      final curve = _entity(
        'curve:reference',
        CadDocumentEntityKind.reference,
        {
          'name': 'Curva de referência',
          'collectionId': 'collection:references',
          'reference': {
            'geometry': {'type': 'curve'},
          },
        },
      );
      final other = _entity(
        'reference:other',
        CadDocumentEntityKind.reference,
        {
          'name': 'Referência futura',
          'collectionId': 'collection:references',
          'reference': {
            'geometry': {'type': 'coordinateSystem'},
          },
        },
      );
      final primitiveSurface = _entity(
        'surface:primitive',
        CadDocumentEntityKind.surface,
        {
          'name': 'Plano primitivo',
          'constructionEntity': {'type': 'primitiveSurface'},
        },
      );
      final nonReferenceCurve = _entity(
        'curve:modified',
        CadDocumentEntityKind.curve,
        {
          'name': 'Curva construída',
          'collectionId': 'collection:modified',
          'constructionEntity': {'type': 'curve'},
        },
      );

      final grouped = ReferenceTreeTaxonomy.grouped([
        ...system,
        point,
        managedAxis(),
        vector,
        managedPlane(),
        curve,
        other,
        primitiveSurface,
        nonReferenceCurve,
      ]);

      expect(grouped[ReferenceTreeGroup.coordinateSystem]!.map((e) => e.id), [
        'project:world:coordinate-system',
        'project:world:origin',
        'project:world:x-axis',
        'project:world:y-axis',
        'project:world:z-axis',
        'project:world:xy-plane',
        'project:world:xz-plane',
        'project:world:yz-plane',
        'reference:other',
      ]);
      expect(grouped[ReferenceTreeGroup.points]!.map((e) => e.id), [
        'point:manual',
      ]);
      expect(grouped[ReferenceTreeGroup.axes]!.map((e) => e.id), [
        'reference:axis',
        'vector:manual',
      ]);
      expect(grouped[ReferenceTreeGroup.planes]!.map((e) => e.id), [
        'reference:plane',
      ]);
      expect(grouped[ReferenceTreeGroup.curves]!.map((e) => e.id), [
        'curve:reference',
      ]);
      expect(grouped[ReferenceTreeGroup.other], isEmpty);
      expect(ReferenceTreeTaxonomy.groupFor(primitiveSurface), isNull);
      expect(ReferenceTreeTaxonomy.groupFor(nonReferenceCurve), isNull);
    },
  );

  test(
    'reports explicit reference origin without mixing CAD and STL contracts',
    () {
      final system = WorldCoordinateSystem.entities('project').values.first;
      final manual = _entity('plane:manual', CadDocumentEntityKind.reference, {
        'collectionId': 'collection:references',
        'constructionEntity': {'type': 'plane'},
      });
      final stlFit = _entity(
        'reference:stl-fit',
        CadDocumentEntityKind.reference,
        {
          'collectionId': 'collection:references',
          'reference': {
            'name': 'Recognized Plane',
            'geometry': {'type': 'plane'},
            'recipe': {
              'sourceIds': ['mesh:stl'],
              'parameters': {'method': 'region', 'tolerance': 0.1},
            },
          },
        },
      );

      expect(ReferenceTreeTaxonomy.originLabel(system), 'Sistema padrão');
      expect(
        ReferenceTreeTaxonomy.originLabel(managedPlane()),
        'Face STEP/BREP — topologia exata',
      );
      expect(ReferenceTreeTaxonomy.originLabel(manual), 'Manual');
      expect(
        ReferenceTreeTaxonomy.originLabel(stlFit),
        'Região STL — ajuste de malha',
      );
    },
  );

  test('document round-trip retains IDs, names and projected groups', () {
    final original = [managedPlane(), managedAxis()];
    final restored = [
      for (final entity in original)
        CadDocumentEntity.fromJson(
          jsonDecode(jsonEncode(entity.toJson())) as Map<String, dynamic>,
        ),
    ];

    expect(restored.map((entity) => entity.id), [
      'reference:plane',
      'reference:axis',
    ]);
    expect(restored.map((entity) => entity.data['name']), [
      'Plano da face',
      'Eixo da face',
    ]);
    expect(
      ReferenceTreeTaxonomy.grouped(
        restored,
      )[ReferenceTreeGroup.planes]!.single.id,
      'reference:plane',
    );
    expect(
      ReferenceTreeTaxonomy.grouped(
        restored,
      )[ReferenceTreeGroup.axes]!.single.id,
      'reference:axis',
    );
  });
}
