import 'dart:io';

import 'package:flcad_mobile/app/cad_viewport/native/native_viewport_bridge.dart';
import 'package:flcad_mobile/app/commands/desktop_command_coordinator.dart';
import 'package:flcad_mobile/app/desktop/desktop_cad_controller.dart';
import 'package:flcad_mobile/app/engineering_bridge/operational_reverse_engineering_controller.dart';
import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/cad_document/managed_cad_reference.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/professional_recognition/api/professional_recognition_api.dart';
import 'package:flcad_mobile/core/reference_engine/api/reference_api.dart';
import 'package:flcad_mobile/core/reference_engine/engine/reference_engine.dart';
import 'package:flcad_mobile/core/reference_engine/repository/reference_repository.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flcad_mobile/features/projects/domain/project_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final caf = Platform.environment['FLCAD_CAD_ASSET_FS_DLL']!;
  final occ = Platform.environment['FLCAD_SOURCE_OCC_DLL']!;
  final bridge = Platform.environment['FLCAD_SOURCE_BRIDGE_DLL']!;
  final fixture = Platform.environment['FLCAD_STEP_FIXTURE_EXE']!;
  late Directory root, source, project;
  late OpenCascadeKernelAdapter adapter;
  late DesktopCadController cad;
  late OperationalReverseEngineeringController controller;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('managed-reference-sketch-');
    source = await Directory(p.join(root.path, 'source')).create();
    project = await Directory(p.join(root.path, 'project')).create();
    final generated = await Process.run(fixture, [caf, bridge, source.path]);
    expect(
      generated.exitCode,
      0,
      reason: '${generated.stdout}\n${generated.stderr}',
    );
    adapter = OpenCascadeKernelAdapter(bridge: OpenCascadeFFI.load(path: occ));
    final projects = ProjectRepository(
      storage: LocalStorageService(rootDirectory: root),
    );
    cad = DesktopCadController(
      kernels: KernelManager()..register(adapter, makeDefault: true),
      projects: ProjectManager.instance,
      projectRepository: projects,
    );
    final commands = DesktopCommandCoordinator(
      cad: cad,
      projects: ProjectManager.instance,
      repository: projects,
    );
    controller = OperationalReverseEngineeringController(
      recognition: ProfessionalRecognitionApi(),
      commands: commands,
      runtime: cad.runtime,
      referenceApi: ReferenceApi(
        engine: ReferenceEngine(
          repository: ReferenceRepository(projects: projects),
        ),
      ),
    );
    await cad.runtime.open('managed-reference-sketch', project);
    await controller.configureProject(
      projectId: 'managed-reference-sketch',
      projectDirectory: project,
    );
  });

  tearDown(() async {
    controller.dispose();
    await cad.runtime.shutdown();
    cad.dispose();
    await adapter.unload();
    await root.delete(recursive: true);
  });

  test(
    'STEP/BREP references drive oriented Sketches and independent rectangle/circle Extrudes',
    () async {
      final step = await cad.runtime.importManagedStep(
        p.join(source.path, 'part-0.step'),
        nativeBridgePath: bridge,
      );
      final stepReferenceId = await cad.runtime.createManagedCadPlaneReference(
        sourceEntityId: step.id,
        presentationTriangleId: 1,
      );
      final stepReference = _reference(cad, stepReferenceId);
      expect(nativeSceneUnsupportedReason(cad.runtime.scene, style: 0), isNull);

      controller.selectSketchSupport(stepReferenceId);
      await controller.openSketch();
      final rectangleSketch = controller.activeSketch!;
      _expectFrame(rectangleSketch, stepReference, stepReferenceId);
      await controller.drawRectangle(
        const SketchVector(-5, -3),
        const SketchVector(5, 3),
      );
      expect(controller.error, isNull);
      expect(rectangleSketch.entityIds, hasLength(4));
      await controller.undo();
      expect(controller.activeSketch!.entityIds, isEmpty);
      await controller.redo();
      expect(controller.activeSketch!.entityIds, hasLength(4));
      final rectangleProfileId = controller.activeSketch!.entityIds.first;
      final circleProfile = controller.sketchApi!.builders.circle.build(
        const SketchVector(12, 0),
        2,
      );
      await controller.finishSketch();
      expect(nativeSceneUnsupportedReason(cad.runtime.scene, style: 0), isNull);
      final rectangleSolid = await _extrudeSketchProfile(
        controller,
        rectangleSketch,
        rectangleProfileId,
        8,
      );
      await cad.runtime.undoDocument();
      expect(cad.runtime.document!.entities[rectangleSolid], isNull);
      await cad.runtime.redoDocument();
      expect(
        cad.runtime.document!.entities[rectangleSolid]?.kind,
        CadDocumentEntityKind.solid,
      );
      final stepCircleSolid = await _extrudeSketchProfile(
        controller,
        rectangleSketch,
        circleProfile.id,
        4,
      );

      final stepAssets = ManagedStepAssets.fromJson(
        Map<String, dynamic>.from(step.data['managedStepAssets'] as Map),
      );
      final brepPath = p.join(
        project.path,
        'CAD',
        'Assets',
        'v1',
        stepAssets.shape.value,
        CadAssetFile.brep.relativePath,
      );
      final brep = await cad.runtime.importManagedBrep(
        brepPath,
        name: 'source-brep',
        nativeBridgePath: bridge,
      );
      final brepReferenceId = await cad.runtime.createManagedCadPlaneReference(
        sourceEntityId: brep.id,
        presentationTriangleId: 1,
      );
      final brepReference = _reference(cad, brepReferenceId);
      controller.selectSketchSupport(brepReferenceId);
      await controller.openSketch();
      final circleSketch = controller.activeSketch!;
      _expectFrame(circleSketch, brepReference, brepReferenceId);
      controller.sketchApi!.builders.circle.build(const SketchVector(0, 0), 4);
      await controller.finishSketch();
      final circleSolid = await _extrudeActiveSketch(controller, 6);

      for (final id in [rectangleSolid, stepCircleSolid, circleSolid]) {
        final solid = cad.runtime.document!.entities[id]!;
        expect(solid.kind, CadDocumentEntityKind.solid);
        expect(solid.shape, isNotNull);
        expect(solid.data['group'], 'Solids');
        expect((solid.data['extrudeFeature'] as Map)['status'], 'committed');
      }
      expect(
        cad.runtime.document!.entities[rectangleSolid]!.shape!.persistentId,
        isNot(step.id),
      );
      expect(
        cad.runtime.document!.entities[circleSolid]!.shape!.persistentId,
        isNot(brep.id),
      );

      await cad.runtime.save();
      final scratch = await Directory(p.join(root.path, 'scratch')).create();
      controller.detachProject();
      await cad.runtime.open('scratch', scratch);
      await cad.runtime.open('managed-reference-sketch', project);
      for (final id in [rectangleSolid, stepCircleSolid, circleSolid]) {
        expect(
          cad.runtime.document!.entities[id]?.kind,
          CadDocumentEntityKind.solid,
        );
        expect(cad.runtime.document!.entities[id]?.shape, isNotNull);
        expect(cad.runtime.scene.find(id), isNotNull);
      }
      expect(
        ((cad.runtime.document!.entities[rectangleSolid]!.data['extrudeFeature']
                as Map)['contract']
            as Map)['profileEntityId'],
        rectangleProfileId,
      );
      expect(
        ((cad
                    .runtime
                    .document!
                    .entities[stepCircleSolid]!
                    .data['extrudeFeature']
                as Map)['contract']
            as Map)['profileEntityId'],
        circleProfile.id,
      );
      final reopenedSketch = Sketch.fromJson(
        Map<String, dynamic>.from(
          cad.runtime.document!.entities[rectangleSketch.id]!.data['sketch']
              as Map,
        ),
      );
      _expectFrame(reopenedSketch, stepReference, stepReferenceId);
    },
  );

  test(
    'orphaned managed CAD reference blocks Sketch creation clearly',
    () async {
      final step = await cad.runtime.importManagedStep(
        p.join(source.path, 'part-0.step'),
        nativeBridgePath: bridge,
      );
      final referenceId = await cad.runtime.createManagedCadPlaneReference(
        sourceEntityId: step.id,
        presentationTriangleId: 1,
      );
      controller.selectSketchSupport(referenceId);
      await cad.runtime.removeEntity(step.id, command: 'test.remove-source');

      await expectLater(
        controller.openSketch(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('órfã'),
          ),
        ),
      );
      expect(
        cad.runtime.document!.entities.values.where(
          (entity) => entity.kind == CadDocumentEntityKind.sketch,
        ),
        isEmpty,
      );
    },
  );
}

ManagedCadReference _reference(DesktopCadController cad, String id) =>
    ManagedCadReference.fromJson(
      Map<String, dynamic>.from(
        cad.runtime.document!.entities[id]!.data[ManagedCadReference.dataKey]
            as Map,
      ),
    );

void _expectFrame(
  Sketch sketch,
  ManagedCadReference reference,
  String referenceId,
) {
  expect(sketch.metadata['supportEntityId'], referenceId);
  expect(sketch.plane.parameters['referenceId'], referenceId);
  expect(sketch.coordinates.origin.toJson(), reference.origin.toJson());
  expect(sketch.coordinates.normal.toJson(), reference.normal.toJson());
  expect(sketch.coordinates.xAxis.toJson(), reference.xDirection.toJson());
  expect(
    sketch.coordinates.xAxis.dot(sketch.coordinates.normal).abs(),
    lessThan(1e-12),
  );
  expect(
    sketch.coordinates.yAxis.dot(sketch.coordinates.normal).abs(),
    lessThan(1e-12),
  );
  expect(
    sketch.coordinates.xAxis.dot(sketch.coordinates.yAxis).abs(),
    lessThan(1e-12),
  );
}

Future<String> _extrudeActiveSketch(
  OperationalReverseEngineeringController controller,
  double distance,
) async {
  final sketch = controller.activeSketch!;
  controller.selectExtrudeSource(sketch.id);
  await controller.previewProfessionalExtrude(distance: distance);
  final preview = controller.professionalExtrudePreview!;
  final id = preview['id'] as String;
  expect(controller.runtime.scene.find('preview:$id'), isNotNull);
  await controller.confirmProfessionalExtrude();
  expect(controller.runtime.scene.find('preview:$id'), isNull);
  expect(controller.runtime.scene.find(id), isNotNull);
  return id;
}

Future<String> _extrudeSketchProfile(
  OperationalReverseEngineeringController controller,
  Sketch sketch,
  String profileEntityId,
  double distance,
) async {
  expect(controller.selectExtrudeSourceFromViewport(profileEntityId), isTrue);
  expect(controller.selectedExtrudeSourceId, sketch.id);
  expect(controller.selectedExtrudeProfileEntityId, profileEntityId);
  await controller.previewProfessionalExtrude(distance: distance);
  final preview = controller.professionalExtrudePreview!;
  final contract = Map<String, dynamic>.from(preview['contract'] as Map);
  expect(contract['profileEntityId'], profileEntityId);
  final id = preview['id'] as String;
  final previewEntity = controller.runtime.scene.find('preview:$id');
  expect(previewEntity, isNotNull);
  expect(previewEntity!.geometry['nodes'], isNotEmpty);
  expect(previewEntity.geometry['triangles'], isNotEmpty);
  expect(
    nativeSceneUnsupportedReason(controller.runtime.scene, style: 0),
    isNull,
  );
  await controller.confirmProfessionalExtrude();
  expect(controller.runtime.scene.find('preview:$id'), isNull);
  expect(controller.runtime.scene.find(id), isNotNull);
  expect(
    nativeSceneUnsupportedReason(controller.runtime.scene, style: 0),
    isNull,
  );
  return id;
}
