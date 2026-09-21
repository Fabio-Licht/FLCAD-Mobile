import 'dart:io';

import 'package:flcad_mobile/app/cad_viewport/native/native_viewport_bridge.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flcad_mobile/app/desktop/contextual_reference_preview_session.dart';
import 'package:flcad_mobile/app/desktop/reference_tree_taxonomy.dart';
import 'package:flcad_mobile/app/entities/entity_plane_service.dart';
import 'package:flcad_mobile/app/entities/entity_point_service.dart';
import 'package:flcad_mobile/app/entities/entity_vector_service.dart';
import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/core/cad_document/alignment_coordinate_system.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late Directory project;
  late CadRuntime runtime;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('alignment-wcs-');
    project = await Directory('${root.path}/project').create();
    runtime = CadRuntime(kernels: KernelManager());
    await runtime.open('alignment-project', project);
  });

  tearDown(() async {
    await runtime.shutdown();
    await root.delete(recursive: true);
  });

  String system(String suffix) => runtime.document!.entities.keys.singleWhere(
    (id) => id.endsWith(':world:$suffix'),
  );

  AlignmentCoordinateSystem definition(
    String id,
  ) => AlignmentCoordinateSystem.fromJson(
    Map<String, dynamic>.from(
      runtime.document!.entities[id]!.data[AlignmentCoordinateSystem.dataKey]
          as Map,
    ),
  );

  test(
    'WCS references create a right-handed preview and durable snapshot',
    () async {
      final preview = await runtime.previewAlignmentCoordinateSystem(
        planeEntityId: system('xy-plane'),
        axisEntityId: system('y-axis'),
        pointEntityId: system('origin'),
      );
      expect(preview.origin.toJson(), [0.0, 0.0, 0.0]);
      expect(preview.xAxis.toJson(), [1.0, 0.0, 0.0]);
      expect(preview.yAxis.toJson(), [0.0, 1.0, 0.0]);
      expect(preview.zAxis.toJson(), [0.0, 0.0, 1.0]);
      expect(
        preview.xAxis.cross(preview.yAxis).toJson(),
        preview.zAxis.toJson(),
      );

      final session = ContextualReferencePreviewSession(runtime);
      session.show(
        CadSceneEntity(
          id: 'draft',
          kind: CadSceneEntityKind.coordinateSystem,
          geometry: {
            'type': 'coordinateSystem',
            'origin': preview.origin.toJson(),
            'xAxis': preview.xAxis.toJson(),
            'yAxis': preview.yAxis.toJson(),
            'zAxis': preview.zAxis.toJson(),
          },
        ),
      );
      expect(nativeSceneUnsupportedReason(runtime.scene, style: 0), isNull);
      session.cancel();

      final id = await runtime.createAlignmentCoordinateSystemReference(
        planeEntityId: system('xy-plane'),
        axisEntityId: system('y-axis'),
        pointEntityId: system('origin'),
      );
      expect(
        ReferenceTreeTaxonomy.groupFor(runtime.document!.entities[id]!),
        ReferenceTreeGroup.coordinateSystem,
      );
      expect(nativeSceneUnsupportedReason(runtime.scene, style: 0), isNull);
      expect(
        runtime.alignmentCoordinateSystemIsOrphaned(definition(id)),
        isFalse,
      );

      await runtime.undoDocument();
      expect(runtime.document!.entities[id], isNull);
      await runtime.redoDocument();
      expect(runtime.document!.entities[id], isNotNull);
    },
  );

  test('rejects axis parallel to plane normal', () async {
    await expectLater(
      runtime.previewAlignmentCoordinateSystem(
        planeEntityId: system('xy-plane'),
        axisEntityId: system('z-axis'),
        pointEntityId: system('origin'),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('paralelo à normal'),
        ),
      ),
    );
  });

  test('manual coordinates persist exactly without a point parent', () async {
    const origin = Vector3(25, -40, 12.5);
    final unrelatedPoint = (await EntityPointService(runtime).create(
      method: ConstructionPointMethod.coordinates,
      coordinates: const Vector3(9, 8, 7),
    )).single;
    final plane = await EntityPlaneService(runtime).create(
      method: ConstructionPlaneMethod.offset,
      sourceEntityIds: [system('xy-plane')],
      distance: 2,
    );
    final axis = await EntityVectorService(runtime).create(
      method: ConstructionVectorMethod.components,
      components: const Vector3(0, 1, 0),
    );
    final preview = await runtime.previewAlignmentCoordinateSystem(
      planeEntityId: plane,
      axisEntityId: axis,
      originKind: AlignmentCoordinateSystemOriginKind.manual,
      manualOrigin: origin,
    );
    expect(preview.origin.toJson(), origin.toJson());
    expect(preview.point, isNull);

    final id = await runtime.createAlignmentCoordinateSystemReference(
      planeEntityId: plane,
      axisEntityId: axis,
      originKind: AlignmentCoordinateSystemOriginKind.manual,
      manualOrigin: origin,
    );
    final snapshot = definition(id);
    expect(snapshot.origin.toJson(), origin.toJson());
    expect(snapshot.originKind, AlignmentCoordinateSystemOriginKind.manual);
    expect(snapshot.point, isNull);
    expect(runtime.document!.entities[id]!.data['sourceEntityIds'], [
      plane,
      axis,
    ]);

    await runtime.save();
    await runtime.open('alignment-project', project);
    final reopened = definition(id);
    expect(reopened.origin.toJson(), origin.toJson());
    expect(runtime.alignmentCoordinateSystemIsOrphaned(reopened), isFalse);
    await runtime.removeEntity(axis, command: 'test.remove-alignment-axis');
    expect(runtime.alignmentCoordinateSystemIsOrphaned(reopened), isTrue);
    await runtime.undoDocument();
    expect(runtime.alignmentCoordinateSystemIsOrphaned(reopened), isFalse);
    await runtime.removeEntity(
      unrelatedPoint,
      command: 'test.remove-unrelated-origin',
    );
    expect(runtime.alignmentCoordinateSystemIsOrphaned(reopened), isFalse);
  });

  test(
    'viewport origin is a value snapshot with explicit provenance',
    () async {
      const hit = Vector3(1.23456789, -2.5, 80.125);
      final id = await runtime.createAlignmentCoordinateSystemReference(
        planeEntityId: system('xy-plane'),
        axisEntityId: system('x-axis'),
        originKind: AlignmentCoordinateSystemOriginKind.viewport,
        manualOrigin: hit,
      );
      final snapshot = definition(id);
      expect(snapshot.origin.toJson(), hit.toJson());
      expect(snapshot.originKind, AlignmentCoordinateSystemOriginKind.viewport);
      expect(snapshot.point, isNull);

      await runtime.undoDocument();
      expect(runtime.document!.entities[id], isNull);
      await runtime.redoDocument();
      expect(definition(id).origin.toJson(), hit.toJson());
    },
  );

  test(
    'manual plane vector and point persist, hide safely and orphan on removal',
    () async {
      final plane = await EntityPlaneService(runtime).create(
        method: ConstructionPlaneMethod.offset,
        sourceEntityIds: [system('xy-plane')],
        distance: 12.5,
      );
      final axis = await EntityVectorService(runtime).create(
        method: ConstructionVectorMethod.components,
        origin: const Vector3(0, 0, 0),
        components: const Vector3(1, 2, 0),
      );
      final point = (await EntityPointService(runtime).create(
        method: ConstructionPointMethod.coordinates,
        coordinates: const Vector3(-40, 0, -25.9),
      )).single;
      final id = await runtime.createAlignmentCoordinateSystemReference(
        planeEntityId: plane,
        axisEntityId: axis,
        pointEntityId: point,
      );
      final snapshot = definition(id);
      expect(snapshot.origin.toJson(), [-40.0, 0.0, -25.9]);
      expect(snapshot.xAxis.dot(snapshot.yAxis).abs(), lessThan(1e-10));
      expect(snapshot.yAxis.dot(snapshot.zAxis).abs(), lessThan(1e-10));
      expect(
        snapshot.xAxis.cross(snapshot.yAxis).distanceTo(snapshot.zAxis),
        lessThan(1e-10),
      );

      await runtime.setEntityVisibility(plane, false);
      expect(runtime.alignmentCoordinateSystemIsOrphaned(snapshot), isFalse);
      await runtime.save();
      await runtime.open('alignment-project', project);
      expect(
        runtime.alignmentCoordinateSystemIsOrphaned(definition(id)),
        isFalse,
      );

      await runtime.removeEntity(point, command: 'test.remove-alignment-point');
      expect(
        runtime.alignmentCoordinateSystemIsOrphaned(definition(id)),
        isTrue,
      );
      await runtime.undoDocument();
      expect(
        runtime.alignmentCoordinateSystemIsOrphaned(definition(id)),
        isFalse,
      );
    },
  );
}
