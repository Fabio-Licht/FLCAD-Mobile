import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/app/cad_viewport/native/native_viewport_bridge.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flcad_mobile/app/desktop/contextual_reference_preview_session.dart';
import 'package:flcad_mobile/app/desktop/reference_tree_taxonomy.dart';
import 'package:flcad_mobile/app/entities/entity_plane_service.dart';
import 'package:flcad_mobile/app/entities/entity_vector_service.dart';
import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/core/cad_document/plane_axis_intersection_point.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late Directory project;
  late CadRuntime runtime;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('plane-axis-point-');
    project = await Directory('${root.path}/project').create();
    runtime = CadRuntime(kernels: KernelManager());
    await runtime.open('intersection-project', project);
  });

  tearDown(() async {
    await runtime.shutdown();
    await root.delete(recursive: true);
  });

  String system(String suffix) => runtime.document!.entities.keys.singleWhere(
    (id) => id.endsWith(':world:$suffix'),
  );

  PlaneAxisIntersectionPoint definition(
    String id,
  ) => PlaneAxisIntersectionPoint.fromJson(
    Map<String, dynamic>.from(
      runtime.document!.entities[id]!.data[PlaneAxisIntersectionPoint.dataKey]
          as Map,
    ),
  );

  test(
    'standard XY plane and Z axis preview and apply one durable point',
    () async {
      final beforeEntities = runtime.document!.entities.length;
      final beforeRevision = runtime.runtimeRevision;
      final preview = await runtime.previewPlaneAxisIntersectionPoint(
        planeEntityId: system('xy-plane'),
        axisEntityId: system('z-axis'),
      );
      expect(preview.point.toJson(), [0.0, 0.0, 0.0]);
      expect(runtime.document!.entities.length, beforeEntities);
      expect(runtime.runtimeRevision, beforeRevision);

      final session = ContextualReferencePreviewSession(runtime);
      session.show(
        CadSceneEntity(
          id: 'ignored',
          kind: CadSceneEntityKind.point,
          geometry: {
            'type': 'point',
            'position': preview.point.toJson(),
            'markerRadius': 5.0,
          },
        ),
      );
      expect(runtime.document!.entities.length, beforeEntities);
      expect(nativeSceneUnsupportedReason(runtime.scene, style: 0), isNull);
      session.cancel();
      expect(runtime.scene.find(ContextualReferencePreviewSession.id), isNull);

      expect(runtime.canUndo, isFalse);
      final id = await runtime.createPlaneAxisIntersectionPointReference(
        planeEntityId: system('xy-plane'),
        axisEntityId: system('z-axis'),
      );
      expect(runtime.document!.entities.length, beforeEntities + 1);
      expect(definition(id).point.toJson(), [0.0, 0.0, 0.0]);
      expect(
        ReferenceTreeTaxonomy.groupFor(runtime.document!.entities[id]!),
        ReferenceTreeGroup.points,
      );
      expect(nativeSceneUnsupportedReason(runtime.scene, style: 0), isNull);

      await runtime.undoDocument();
      expect(runtime.document!.entities[id], isNull);
      expect(runtime.canUndo, isFalse);
      await runtime.redoDocument();
      expect(runtime.document!.entities[id], isNotNull);
    },
  );

  test('parallel and contained axes are rejected as non-unique', () async {
    final vectors = EntityVectorService(runtime);
    final parallel = await vectors.create(
      method: ConstructionVectorMethod.components,
      origin: const Vector3(0, 0, 4),
      components: const Vector3(1, 0, 0),
    );
    await expectLater(
      runtime.previewPlaneAxisIntersectionPoint(
        planeEntityId: system('xy-plane'),
        axisEntityId: parallel,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('paralelo'),
        ),
      ),
    );
    await expectLater(
      runtime.previewPlaneAxisIntersectionPoint(
        planeEntityId: system('xy-plane'),
        axisEntityId: system('x-axis'),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('contido'),
        ),
      ),
    );
  });

  test('manual offset plane uses exact world intersection', () async {
    final plane = await EntityPlaneService(runtime).create(
      method: ConstructionPlaneMethod.offset,
      sourceEntityIds: [system('xy-plane')],
      distance: 12.5,
    );
    final result = await runtime.previewPlaneAxisIntersectionPoint(
      planeEntityId: plane,
      axisEntityId: system('z-axis'),
    );
    expect(result.point.toJson(), [0.0, 0.0, 12.5]);
  });

  test(
    'snapshot survives save/open and visibility but reports removed parent',
    () async {
      final plane = await EntityPlaneService(runtime).create(
        method: ConstructionPlaneMethod.offset,
        sourceEntityIds: [system('xy-plane')],
        distance: 3,
      );
      final axis = await EntityVectorService(runtime).create(
        method: ConstructionVectorMethod.components,
        origin: const Vector3(2, 4, 0),
        components: const Vector3(0, 0, 1),
      );
      final id = await runtime.createPlaneAxisIntersectionPointReference(
        planeEntityId: plane,
        axisEntityId: axis,
      );
      final snapshot = definition(id);
      expect(snapshot.point.toJson(), [2.0, 4.0, 3.0]);
      expect(runtime.planeAxisIntersectionPointIsOrphaned(snapshot), isFalse);

      await runtime.setEntityVisibility(plane, false);
      await runtime.setEntityVisibility(axis, false);
      expect(runtime.planeAxisIntersectionPointIsOrphaned(snapshot), isFalse);
      expect(runtime.scene.find(id)?.visible, isTrue);

      await runtime.save();
      await runtime.open(
        'scratch',
        await Directory('${root.path}/scratch').create(),
      );
      await runtime.open('intersection-project', project);
      final restored = definition(id);
      expect(restored.point.toJson(), [2.0, 4.0, 3.0]);
      expect(runtime.planeAxisIntersectionPointIsOrphaned(restored), isFalse);

      await runtime.removeEntity(plane, command: 'test.remove-plane-parent');
      expect(runtime.planeAxisIntersectionPointIsOrphaned(restored), isTrue);
      expect(runtime.document!.entities[id], isNotNull);
      await runtime.undoDocument();
      expect(
        runtime.planeAxisIntersectionPointIsOrphaned(definition(id)),
        isFalse,
      );

      final encoded = jsonEncode(runtime.document!.entities[id]!.toJson());
      for (final forbidden in ['pathname', 'pointer', 'primitiveId', 'token']) {
        expect(encoded, isNot(contains(forbidden)));
      }
    },
  );
}
