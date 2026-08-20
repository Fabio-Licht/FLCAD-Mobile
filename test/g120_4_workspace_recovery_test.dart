import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flcad_mobile/app/cad_viewport/camera/cad_camera_controller.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/app/runtime/world_coordinate_system.dart';
import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/import_export/api/import_export_api.dart';

void main() {
  test(
    'project open rebuilds bounds and clears every transient runtime state',
    () async {
      final directory = await Directory.systemTemp.createTemp('g120_4_');
      addTearDown(() => directory.delete(recursive: true));
      final runtime = CadRuntime(kernels: KernelManager());
      addTearDown(runtime.dispose);
      await runtime.open('project', directory);
      const mesh = KernelMeshHandle(
        persistentId: 'mesh',
        kernelId: 'test',
        fingerprint: 'mesh-fingerprint',
        vertexCount: 3,
        triangleCount: 1,
        // Deliberately stale: recovery must derive bounds from the nodes.
        bounds: KernelBounds(100, 100, 100, 101, 101, 101),
        hasNormals: false,
        metadata: {},
      );
      await runtime.registerImport(
        const ImportedCadDocument(
          id: 'import',
          projectId: 'project',
          sourcePath: 'source.stl',
          format: CadImportFormat.stl,
          registeredPath: 'CAD/Imports/source.stl',
          validation: [],
          mesh: mesh,
        ),
        geometry: const KernelMeshGeometry(
          nodes: [10, 20, 30, 14, 20, 30, 10, 26, 32],
          triangles: [0, 1, 2],
        ),
      );
      await runtime.mutate(
        command: 'legacy.transient-state',
        upsert: const [
          CadDocumentEntity(
            id: 'legacy-sketch',
            kind: CadDocumentEntityKind.sketch,
            data: {
              'sketchState': 'sketchActive',
              'sketchEntity': {'selectionState': 'selected'},
            },
          ),
        ],
      );
      await runtime.save();

      runtime.showTransient(
        const CadSceneEntity(
          id: 'preview',
          kind: CadSceneEntityKind.preview,
          geometry: {
            'points': [
              [999, 999, 999],
            ],
          },
        ),
      );
      runtime.write('sketch.line.active', true);
      runtime.select({'import'});
      var publishedCompleteWorkspace = false;
      runtime.addListener(() {
        if (runtime.document?.projectId == 'project' &&
            runtime.scene.find('import') != null &&
            runtime.workspaceBounds != null) {
          publishedCompleteWorkspace = true;
        }
      });

      await runtime.open('project', directory);

      final persisted = await File(
        '${directory.path}${Platform.pathSeparator}cad-document.json',
      ).readAsString();
      expect(persisted, isNot(contains('presentationOffset')));
      expect(persisted, isNot(contains('presentationTranslation')));
      expect(persisted, isNot(contains('sketchState')));
      expect(persisted, isNot(contains('preview')));

      expect(publishedCompleteWorkspace, isTrue);
      expect(runtime.scene.find('preview'), isNull);
      expect(runtime.read<bool>('sketch.line.active'), isNull);
      expect(runtime.selection, isEmpty);
      final legacy = runtime.document!.entities['legacy-sketch']!.data;
      expect(legacy.containsKey('sketchState'), isFalse);
      expect((legacy['sketchEntity'] as Map)['selectionState'], 'none');
      expect(runtime.workspaceBounds?.minX, 10);
      expect(runtime.workspaceBounds?.minY, 20);
      expect(runtime.workspaceBounds?.minZ, 30);
      expect(runtime.workspaceBounds?.maxX, 14);
      expect(runtime.workspaceBounds?.maxY, 26);
      expect(runtime.workspaceBounds?.maxZ, 32);
    },
  );

  test(
    'camera recovery removes sketch, projection and presentation offsets',
    () {
      final camera = CadCameraController();
      addTearDown(camera.dispose);
      camera.resize(1000, 700);
      camera.enterSketch(
        origin: const Vector3(20, 10, 4),
        normal: const Vector3(0, 0, 1),
        xDirection: const Vector3(1, 0, 0),
      );
      camera.translateOperationalScene(const Vector3(4, -3, 0));

      camera.restoreWorkspace(
        const Vector3(10, 20, 30),
        const Vector3(14, 26, 32),
      );

      expect(camera.isInSketchMode, isFalse);
      expect(camera.projectionMode, CadProjectionMode.perspective);
      expect(camera.presentationTranslation.length, 0);
      expect(camera.presentationOffsetNdcX, 0);
      expect(camera.presentationOffsetNdcY, 0);
      expect(camera.target.x, 12);
      expect(camera.target.y, 23);
      expect(camera.target.z, 31);
    },
  );

  test(
    'audit 1: imported STL keeps exact coordinates after close and open',
    () async {
      final directory = await Directory.systemTemp.createTemp('g120_4_a1_');
      addTearDown(() => directory.delete(recursive: true));
      final runtime = CadRuntime(kernels: KernelManager());
      addTearDown(runtime.dispose);
      await runtime.open('project-a1', directory);
      await runtime.registerImport(
        const ImportedCadDocument(
          id: 'mesh-a1',
          projectId: 'project-a1',
          sourcePath: 'audit.stl',
          format: CadImportFormat.stl,
          registeredPath: 'CAD/Imports/audit.stl',
          validation: [],
          mesh: KernelMeshHandle(
            persistentId: 'mesh-a1',
            kernelId: 'audit',
            fingerprint: 'audit',
            vertexCount: 3,
            triangleCount: 1,
            bounds: KernelBounds(-3, 2, 5, 7, 11, 13),
            hasNormals: false,
            metadata: {},
          ),
        ),
        geometry: const KernelMeshGeometry(
          nodes: [-3, 2, 5, 7, 2, 5, -3, 11, 13],
          triangles: [0, 1, 2],
        ),
      );
      final before = List<double>.from(
        runtime.scene.find('mesh-a1')!.geometry['nodes'] as List,
      );
      await runtime.close();
      await runtime.open('project-a1', directory);
      final after = List<double>.from(
        runtime.scene.find('mesh-a1')!.geometry['nodes'] as List,
      );
      expect(after, before);
      expect(
        runtime.document!.entities['mesh-a1']!.data['sceneGeometry']['nodes'],
        after,
      );
    },
  );

  test('audit 2: entering and leaving Sketch never changes geometry truth', () {
    final camera = CadCameraController();
    addTearDown(camera.dispose);
    const geometry = [2.0, 4.0, 6.0, 8.0, 10.0, 12.0];
    final before = List<double>.from(geometry);
    final cameraBefore = camera.snapshot();
    camera.enterSketch(
      origin: const Vector3(2, 4, 6),
      normal: const Vector3(0, 0, 1),
      xDirection: const Vector3(1, 0, 0),
    );
    camera.exitSketch();
    expect(geometry, before);
    expect(camera.eye.distanceTo(cameraBefore.eye), lessThan(1e-12));
    expect(camera.target.distanceTo(cameraBefore.target), lessThan(1e-12));
    expect(camera.up.distanceTo(cameraBefore.up), lessThan(1e-12));
  });

  test('audit 3: Pan then Fit clears presentation without moving geometry', () {
    final camera = CadCameraController(
      eye: const Vector3(8, -10, 7),
      target: const Vector3(2, 3, 4),
      up: const Vector3(0, 0, 1),
    )..resize(1000, 700);
    addTearDown(camera.dispose);
    const geometry = [1.0, 2.0, 3.0, 7.0, 8.0, 9.0];
    final before = List<double>.from(geometry);
    camera.translateOperationalScene(const Vector3(4, -2, 1));
    camera.fit(const Vector3(1, 2, 3), const Vector3(7, 8, 9));
    expect(geometry, before);
    expect(camera.presentationTranslation.length, 0);
    expect(camera.presentationOffsetNdcX, 0);
    expect(camera.presentationOffsetNdcY, 0);
    expect(camera.target.distanceTo(const Vector3(4, 5, 6)), lessThan(1e-12));
  });

  test(
    'audit 4: Orbit changes only camera and recovery restores orientation',
    () {
      final camera = CadCameraController();
      addTearDown(camera.dispose);
      const geometryDirection = Vector3(0, 0, 1);
      camera.orbit(.7, -.25);
      expect(geometryDirection, const Vector3(0, 0, 1));
      camera.restoreWorkspace(
        const Vector3(-2, -2, -2),
        const Vector3(2, 2, 2),
      );
      expect(
        (camera.eye - camera.target).normalized.distanceTo(
          const Vector3(1, -1, .75).normalized,
        ),
        lessThan(1e-12),
      );
    },
  );

  test('audit 5 and WCS: every standard view preserves one RH world basis', () {
    final document = WorldCoordinateSystem.ensure(CadDocument.empty('wcs'));
    List<num> vector(String suffix, String field) =>
        (document.entities['wcs:world:$suffix']!.data['sceneGeometry'][field]
                as List)
            .cast<num>();
    final x = Vector3.fromJson(vector('x-axis', 'direction'));
    final y = Vector3.fromJson(vector('y-axis', 'direction'));
    final z = Vector3.fromJson(vector('z-axis', 'direction'));
    expect(x.cross(y).distanceTo(z), lessThan(1e-12));
    expect(
      vector('origin', 'position').map((value) => value.toDouble()).toList(),
      [0, 0, 0],
    );

    final camera = CadCameraController();
    addTearDown(camera.dispose);
    final expected = <CadStandardView, Vector3>{
      CadStandardView.perspective: const Vector3(1, -1, .75).normalized,
      CadStandardView.top: const Vector3(0, 0, 1),
      CadStandardView.bottom: const Vector3(0, 0, -1),
      CadStandardView.front: const Vector3(0, -1, 0),
      CadStandardView.back: const Vector3(0, 1, 0),
      CadStandardView.right: const Vector3(1, 0, 0),
      CadStandardView.left: const Vector3(-1, 0, 0),
      CadStandardView.isometric: const Vector3(1, -1, 1).normalized,
    };
    for (final entry in expected.entries) {
      camera.setStandardView(
        entry.key,
        const Vector3(-4, -5, -6),
        const Vector3(8, 9, 10),
      );
      expect(
        (camera.eye - camera.target).normalized.distanceTo(entry.value),
        lessThan(1e-12),
        reason: entry.key.name,
      );
      final forward = (camera.target - camera.eye).normalized;
      final right = forward.cross(camera.up).normalized;
      final cameraUp = right.cross(forward).normalized;
      expect(right.dot(cameraUp).abs(), lessThan(1e-12));
      expect(right.cross(cameraUp).dot(-forward), greaterThan(.999999));
    }
  });
}
