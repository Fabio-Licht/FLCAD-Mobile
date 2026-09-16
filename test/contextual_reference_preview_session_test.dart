import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_bounds.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flcad_mobile/app/desktop/contextual_reference_preview_session.dart';
import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'one contextual preview is transient and cancel leaves no scene residue',
    () {
      final runtime = CadRuntime(kernels: KernelManager());
      final session = ContextualReferencePreviewSession(runtime);
      session.show(
        const CadSceneEntity(
          id: 'any',
          kind: CadSceneEntityKind.plane,
          geometry: {
            'origin': [0, 0, 0],
            'normal': [0, 0, 1],
          },
        ),
      );
      expect(
        runtime.scene.find(ContextualReferencePreviewSession.id),
        isNotNull,
      );
      session.cancel();
      expect(runtime.scene.find(ContextualReferencePreviewSession.id), isNull);
      expect(runtime.document, isNull);
    },
  );

  test(
    'a new preview replaces the prior analytic descriptor without persistence',
    () {
      final runtime = CadRuntime(kernels: KernelManager());
      final session = ContextualReferencePreviewSession(runtime);
      session.show(
        const CadSceneEntity(
          id: 'plane-preview',
          kind: CadSceneEntityKind.plane,
          geometry: {
            'origin': [12.0, 4.0, -3.0],
            'normal': [0.0, 1.0, 0.0],
            'xDirection': [1.0, 0.0, 0.0],
          },
        ),
      );
      session.show(
        const CadSceneEntity(
          id: 'axis-preview',
          kind: CadSceneEntityKind.axis,
          geometry: {
            'origin': [8.0, 2.0, 1.0],
            'direction': [0.0, 0.0, 1.0],
            'radius': 6.5,
          },
        ),
      );

      final preview = runtime.scene.find(ContextualReferencePreviewSession.id);
      expect(preview?.kind, CadSceneEntityKind.axis);
      expect(preview?.geometry['origin'], [8.0, 2.0, 1.0]);
      expect(preview?.geometry['direction'], [0.0, 0.0, 1.0]);
      expect(preview?.geometry['radius'], 6.5);
      expect(runtime.document, isNull);
    },
  );

  test(
    'preview changes no document history files hashes or CAD bounds',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'contextual-reference-preview-',
      );
      addTearDown(() => root.delete(recursive: true));
      final runtime = CadRuntime(kernels: KernelManager());
      await runtime.open('preview-project', root);
      runtime.scene.upsert(
        const CadSceneEntity(
          id: 'durable-cad-probe',
          kind: CadSceneEntityKind.solid,
          geometry: {
            'nodes': [0.0, 0.0, 0.0, 10.0, 20.0, 30.0],
            'triangles': [0, 1, 1],
          },
        ),
      );
      final beforeDocument = jsonEncode(runtime.document!.toJson());
      final beforeRevision = runtime.runtimeRevision;
      final beforeUndo = runtime.canUndo;
      final beforeBounds = cadSceneContentBounds(runtime.scene);
      final beforeFiles = <String, String>{
        for (final file in root.listSync(recursive: true).whereType<File>())
          file.path: base64Encode(await file.readAsBytes()),
      };

      final session = ContextualReferencePreviewSession(runtime);
      session.show(
        const CadSceneEntity(
          id: 'ignored',
          kind: CadSceneEntityKind.plane,
          geometry: {
            'origin': [1000000.0, 1000000.0, 1000000.0],
            'normal': [0.0, 0.0, 1.0],
            'visualSize': 1000000.0,
          },
        ),
      );

      expect(jsonEncode(runtime.document!.toJson()), beforeDocument);
      expect(runtime.runtimeRevision, beforeRevision);
      expect(runtime.canUndo, beforeUndo);
      final afterBounds = cadSceneContentBounds(runtime.scene);
      expect(afterBounds?.minimum.toJson(), beforeBounds?.minimum.toJson());
      expect(afterBounds?.maximum.toJson(), beforeBounds?.maximum.toJson());
      expect(<String, String>{
        for (final file in root.listSync(recursive: true).whereType<File>())
          file.path: base64Encode(await file.readAsBytes()),
      }, beforeFiles);

      session.cancel();
      await runtime.shutdown();
    },
  );

  test('contextual cancel never removes the independent Extrude preview', () {
    final runtime = CadRuntime(kernels: KernelManager());
    runtime.showTransient(
      const CadSceneEntity(
        id: 'preview:extrude-probe',
        kind: CadSceneEntityKind.preview,
        geometry: {
          'nodes': [0.0, 0.0, 0.0],
          'triangles': <int>[],
        },
      ),
    );
    final session = ContextualReferencePreviewSession(runtime);
    session.show(
      const CadSceneEntity(
        id: 'ignored',
        kind: CadSceneEntityKind.axis,
        geometry: {
          'origin': [0.0, 0.0, 0.0],
          'direction': [1.0, 0.0, 0.0],
        },
      ),
    );

    session.cancel();

    expect(runtime.scene.find(ContextualReferencePreviewSession.id), isNull);
    expect(runtime.scene.find('preview:extrude-probe'), isNotNull);
  });
}
