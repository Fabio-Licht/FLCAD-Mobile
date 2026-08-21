import 'dart:io';

import 'package:flcad_mobile/app/commands/desktop_command_coordinator.dart';
import 'package:flcad_mobile/app/desktop/desktop_cad_controller.dart';
import 'package:flcad_mobile/app/desktop/desktop_application.dart';
import 'package:flcad_mobile/app/engineering_bridge/operational_reverse_engineering_controller.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/professional_recognition/api/professional_recognition_api.dart';
import 'package:flcad_mobile/core/reference_engine/api/reference_api.dart';
import 'package:flcad_mobile/core/reference_engine/engine/reference_engine.dart';
import 'package:flcad_mobile/core/reference_engine/repository/reference_repository.dart';
import 'package:flcad_mobile/core/sketch_engine/entities/sketch_entities.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flcad_mobile/features/projects/domain/project_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets('Inspector field owns ENTER before the Workspace shortcut', (
    tester,
  ) async {
    double? submitted;
    var workspaceEnter = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): () {
              workspaceEnter++;
            },
          },
          child: Scaffold(
            body: SketchInspectorNumberProperty(
              label: 'Length',
              value: 10,
              onSubmitted: (value) async => submitted = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), '100');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(submitted, 100);
    expect(workspaceEnter, 0);

    submitted = null;
    await tester.enterText(find.byType(TextFormField), '125');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(submitted, 125);
  });

  test(
    'Inspector command updates viewport, document and Undo/Redo in place',
    () async {
      final directory = await Directory.systemTemp.createTemp('g124_1_');
      addTearDown(() => directory.delete(recursive: true));
      final kernels = KernelManager()
        ..register(_HealthySurfaceKernel(), makeDefault: true);
      final cad = DesktopCadController(
        kernels: kernels,
        projects: ProjectManager.instance,
      );
      final commands = DesktopCommandCoordinator(
        cad: cad,
        projects: ProjectManager.instance,
      );
      final projects = ProjectRepository(
        storage: LocalStorageService(rootDirectory: directory),
      );
      final controller = OperationalReverseEngineeringController(
        recognition: ProfessionalRecognitionApi(),
        commands: commands,
        runtime: cad.runtime,
        referenceApi: ReferenceApi(
          engine: ReferenceEngine(
            repository: ReferenceRepository(projects: projects),
          ),
        ),
      );
      addTearDown(controller.dispose);
      addTearDown(cad.dispose);
      await cad.runtime.open('g124-project', directory);
      await controller.configureProject(
        projectId: 'g124-project',
        projectDirectory: directory,
      );
      controller.selectWorldSketchPlane(SketchPlaneType.xy);
      final firstSupport = controller.activeSketchPlaneId;
      controller.selectWorldSketchPlane(SketchPlaneType.yz);
      expect(controller.activeSketchPlaneId, isNot(firstSupport));
      expect(controller.activeSketchPlaneId, endsWith('yz-plane'));
      expect(controller.activeSketchPlane!.normal.x.abs(), closeTo(1, 1e-12));
      controller.selectWorldSketchPlane(SketchPlaneType.xy);
      await controller.openSketch();
      final line = controller.sketchApi!.builders.line.build(
        const SketchVector(0, 0),
        const SketchVector(10, 0),
      );
      controller.toggleSketchSelection(line.id);

      await controller.updateSketchEntityParameters(line.id, {'length': 100});
      final edited = controller.sketchApi!.entity(line.id)! as SketchLine;
      expect(edited.id, line.id);
      expect(edited.parameters['length'], closeTo(100, 1e-10));
      expect(cad.runtime.scene.find(line.id), isNotNull);
      expect(
        cad.runtime.document!.entities[line.id]!.data['sketchEntity']['id'],
        line.id,
      );

      await controller.updateSketchEntityParameters(line.id, {
        'angleDegrees': 45,
      });
      expect(edited.parameters['angleDegrees'], closeTo(45, 1e-10));
      await controller.undo();
      expect(
        controller.sketchApi!.entity(line.id)!.parameters['angleDegrees'],
        closeTo(0, 1e-10),
      );
      await controller.redo();
      expect(
        controller.sketchApi!.entity(line.id)!.parameters['angleDegrees'],
        closeTo(45, 1e-10),
      );

      controller.beginCircleCommand();
      expect(controller.selectedSketchEntityIds, isEmpty);
      expect(cad.runtime.scene.find(line.id)!.selected, isFalse);
      final circle = controller.sketchApi!.builders.circle.build(
        const SketchVector(20, 20),
        5,
      );
      await controller.updateSketchEntityParameters(circle.id, {'radius': 12});
      controller.selectSketchEntity(circle.id);
      expect(controller.selectedSketchEntityIds, {circle.id});
      expect(cad.runtime.scene.find(line.id)!.selected, isFalse);
      expect(cad.runtime.scene.find(circle.id)!.selected, isTrue);
    },
  );
}

class _HealthySurfaceKernel
    implements GeometryKernelAPI, SurfaceOperationKernelAPI {
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'g124-test',
    name: 'G-124 test kernel',
    version: '1',
    capabilities: KernelCapabilities({KernelCapability.planeSurface}),
    vendor: 'FLCAD',
  );

  @override
  Future<KernelHealth> healthCheck() async =>
      KernelHealth(KernelHealthStatus.healthy, 'ok', DateTime(2000));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
