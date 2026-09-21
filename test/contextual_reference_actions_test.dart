import 'package:flcad_mobile/app/cad_viewport/selection/viewport_picking_controller.dart';
import 'package:flcad_mobile/app/desktop/contextual_reference_actions.dart';
import 'package:flcad_mobile/app/engineering_bridge/contracts/bridge_selection.dart';
import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

CadViewportPick facePick(String id) => CadViewportPick(
  entityId: id,
  subentityKind: CadViewportSubentityKind.face,
  presentationSubId: 1,
  hit: MeshHit(triangleIndex: 0, point: Vector3.zero, distance: 0),
);

CadDocumentEntity entity(String id, Map<String, dynamic> data) =>
    CadDocumentEntity(id: id, kind: CadDocumentEntityKind.import, data: data);

void main() {
  test('routes a planar STEP face only to the exact plane command', () {
    final result = ContextualReferenceActions.plan(
      entity: entity('step', {'managedStepAssets': {}}),
      pick: facePick('step'),
      managedFaceSurfaceType: 'plane',
    );
    expect(result.actions, [ContextualReferenceAction.plane]);
    expect(result.origin, 'Face STEP/BREP — topologia exata');
  });

  test('routes a cylindrical STEP face only to the exact axis command', () {
    final result = ContextualReferenceActions.plan(
      entity: entity('step', {'managedStepAssets': {}}),
      pick: facePick('step'),
      managedFaceSurfaceType: 'cylinder',
    );
    expect(result.actions, [ContextualReferenceAction.axis]);
  });

  test('routes an accepted STL region only to its recognized plane', () {
    final result = ContextualReferenceActions.plan(
      entity: entity('stl', {'managedStlAssets': {}}),
      pick: facePick('stl'),
      recognizedStlPlaneAvailable: true,
    );
    expect(result.actions, [ContextualReferenceAction.plane]);
    expect(result.origin, 'Região STL — ajuste de malha');
  });

  test('offers only existing manual handlers without a selection', () {
    final result = ContextualReferenceActions.plan();
    expect(result.actions, [
      ContextualReferenceAction.manualPoint,
      ContextualReferenceAction.manualPlane,
      ContextualReferenceAction.manualAxis,
      ContextualReferenceAction.planeAxisIntersectionPoint,
      ContextualReferenceAction.alignmentCoordinateSystem,
    ]);
    expect(result.showManualSection, isTrue);
  });

  test('legacy Geometry creation stays global with and without selection', () {
    expect(GeometryCreateActions.visible(), GeometryCreateActions.global);
    expect(GeometryCreateActions.visible().map((action) => action.menuLabel), [
      '📍  Ponto',
      '▱  Plano',
      '↗  Vetor',
      '⌁  Curva',
    ]);
    expect(
      GeometryCreateActions.visible(
        selectedEntity: entity('selected-step', {'managedStepAssets': {}}),
        viewportPick: facePick('selected-step'),
      ),
      const [
        GeometryCreateAction.point,
        GeometryCreateAction.plane,
        GeometryCreateAction.vector,
        GeometryCreateAction.curve,
      ],
    );
  });

  test(
    'hides unsupported face options instead of enabling a false command',
    () {
      final result = ContextualReferenceActions.plan(
        entity: entity('step', {'managedStepAssets': {}}),
        pick: facePick('step'),
        managedFaceSurfaceType: 'sphere',
      );
      expect(result.actions, isEmpty);
      expect(result.unavailable, isNotNull);
    },
  );

  test('an existing plane reference never falls back to creation actions', () {
    final result = ContextualReferenceActions.plan(
      entity: CadDocumentEntity(
        id: 'plane',
        kind: CadDocumentEntityKind.reference,
        data: {'collectionId': 'collection:references', 'sceneKind': 'plane'},
      ),
    );
    expect(result.origin, 'Referência existente');
    expect(result.actions, isEmpty);
    expect(result.showManualSection, isFalse);
  });

  test('an existing axis reference wins over a stale viewport pick', () {
    final result = ContextualReferenceActions.plan(
      entity: CadDocumentEntity(
        id: 'axis',
        kind: CadDocumentEntityKind.reference,
        data: {'collectionId': 'collection:references', 'sceneKind': 'axis'},
      ),
      pick: facePick('stale-face-pick'),
      managedFaceSurfaceType: 'plane',
    );
    expect(result.origin, 'Referência existente');
    expect(result.actions, isEmpty);
  });

  test(
    'a standard system plane routes to the existing manual plane handler',
    () {
      final result = ContextualReferenceActions.plan(
        entity: CadDocumentEntity(
          id: 'world:xy-plane',
          kind: CadDocumentEntityKind.reference,
          data: {'systemProtected': true, 'sceneKind': 'plane'},
        ),
      );
      expect(result.actions, [ContextualReferenceAction.manualPlane]);
      expect(result.origin, 'Sistema padrão — plano de suporte');
    },
  );
}
