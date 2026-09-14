import 'dart:io';
import 'dart:convert';

import 'package:flcad_mobile/app/desktop/desktop_cad_controller.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flcad_mobile/features/projects/domain/project_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flcad_mobile/core/cad_document/managed_step_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final locator = Platform.environment['FLCAD_REAL_STEP_SOURCE'];
  final expectedHash = Platform.environment['FLCAD_REAL_STEP_SHA256'];
  test(
    'Windows STEP controller imports recoverable real SI unit with warning',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'real-step-ui-project-',
      );
      final repository = ProjectRepository(
        storage: LocalStorageService(rootDirectory: root),
      );
      final projects = ProjectManager(repository: repository);
      final project = await projects.create(
        name: 'STEP diagnostic',
        client: 'Test',
      );
      final adapter = OpenCascadeKernelAdapter(
        bridge: OpenCascadeFFI.load(
          path: Platform.environment['FLCAD_SOURCE_OCC_DLL']!,
        ),
      );
      late final DesktopCadController controller;
      controller = DesktopCadController(
        kernels: KernelManager()..register(adapter, makeDefault: true),
        projects: projects,
        projectRepository: repository,
        // Supply picker and test DLL configuration. The admitted source and
        // productive runtime import/transaction remain unchanged.
        managedStepFilePicker: (_) async => locator,
        managedStepImporter: (source, cancellation) =>
            controller.runtime.importManagedStep(
              source,
              cancellation: cancellation,
              nativeBridgePath: Platform.environment['FLCAD_SOURCE_BRIDGE_DLL'],
            ),
      );
      final logs = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      try {
        await controller.runtime.open(
          project.id,
          await repository.directoryFor(project.id),
        );
        final before = controller.runtime.document!.toJson();
        final sceneBefore = controller.runtime.scene.entities.toList();
        await controller.pickAndImportManagedStep();
        expect(
          controller.message,
          contains('Aviso: importado em modo de compatibilidade STEP'),
          reason: logs
              .where((line) => line.startsWith('[managed-step]'))
              .join('\n'),
        );
        expect(logs.join(), isNot(contains(locator!)));
        expect(controller.runtime.document!.toJson(), isNot(before));
        expect(
          jsonEncode(controller.runtime.document!.toJson()),
          isNot(contains(locator)),
        );
        expect(
          controller.runtime.scene.entities.length,
          sceneBefore.length + 1,
        );
        final entity = controller.runtime.document!.entities.values.singleWhere(
          (e) => e.data['managedStepAssets'] != null,
        );
        expect(controller.runtime.selection, {entity.id});
        final refs = entity.data['managedStepAssets'] as Map;
        final projectPath = await repository.directoryFor(project.id);
        final appearanceId = (refs['appearanceManifestAssetId'] as Map)['id'];
        final manifest = StepAppearanceManifest.fromJson(
          jsonDecode(
                await File(
                  '${projectPath.path}/CAD/Assets/v1/$appearanceId/appearance.json',
                ).readAsString(),
              )
              as Map<String, dynamic>,
        );
        expect(manifest.usedCompatibility, isTrue);
        expect(manifest.compatibilitySourceSha256, expectedHash!.toLowerCase());
        expect(adapter.custodyDiagnostics!.leases, 0);
        expect(adapter.custodyDiagnostics!.allocations, 2);
      } finally {
        debugPrint = previousDebugPrint;
        await controller.runtime.shutdown();
        controller.dispose();
        projects.dispose();
        await adapter.unload();
        await root.delete(recursive: true);
      }
    },
    skip: locator == null || expectedHash == null
        ? 'Requires explicit local source and independently computed SHA-256'
        : false,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
