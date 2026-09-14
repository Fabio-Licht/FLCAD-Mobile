import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

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
        final display =
            controller.runtime.scene
                    .find(entity.id)!
                    .geometry['brepPresentation']
                as Map;
        expect(display['normalsOrigin'], 'brepSurface');
        expect(display['topologicalEdges'], isNotEmpty);
        final nodes = (display['nodes'] as List).cast<num>();
        final normals = (display['normals'] as List).cast<num>();
        expect(normals.length, nodes.length);
        // Validate imported surface normals against oriented triangle winding;
        // lighting must never repair an inverted normal by facing the camera.
        final triangles = (display['triangles'] as List).cast<num>();
        var testedNormals = 0;
        var minAlignment = 1.0;
        var opposedNormals = 0;
        var totalArea = 0.0, opposedArea = 0.0;
        for (var t = 0; t < triangles.length; t += 3) {
          final a = triangles[t].toInt() * 3;
          final b = triangles[t + 1].toInt() * 3;
          final c = triangles[t + 2].toInt() * 3;
          final ux = nodes[b] - nodes[a],
              uy = nodes[b + 1] - nodes[a + 1],
              uz = nodes[b + 2] - nodes[a + 2];
          final vx = nodes[c] - nodes[a],
              vy = nodes[c + 1] - nodes[a + 1],
              vz = nodes[c + 2] - nodes[a + 2];
          final x = uy * vz - uz * vy,
              y = uz * vx - ux * vz,
              z = ux * vy - uy * vx;
          final area = math.sqrt(x * x + y * y + z * z);
          if (area < 1e-12) continue;
          totalArea += area;
          var opposed = false;
          for (final offset in [a, b, c]) {
            final nx = normals[offset],
                ny = normals[offset + 1],
                nz = normals[offset + 2];
            final length = math.sqrt(nx * nx + ny * ny + nz * nz);
            expect(length.isFinite, isTrue);
            expect(length, closeTo(1, 1e-5));
            final alignment = (x * nx + y * ny + z * nz) / (area * length);
            minAlignment = math.min(minAlignment, alignment);
            if (alignment <= 0) {
              opposedNormals++;
              opposed = true;
            }
            testedNormals++;
          }
          if (opposed) opposedArea += area;
        }
        expect(testedNormals, greaterThan(0));
        // Local analytic ambiguity at a nearly collinear boundary is recorded,
        // not repaired by a camera-facing flip. Detect any broad regression.
        expect(opposedArea / totalArea, lessThan(1e-7));
        previousDebugPrint(
          '[viewport-normals] checked=$testedNormals opposed=$opposedNormals minAlignment=$minAlignment',
        );
        // Opt-in, test-only capture input contains presentation geometry only.
        // Source bytes, source identity and managed residence are never exported.
        final capture = Platform.environment['FLCAD_VIEWPORT_CAPTURE_GEOMETRY'];
        if (capture != null) {
          final sceneGeometry = controller.runtime.scene
              .find(entity.id)!
              .geometry;
          await File(capture).writeAsString(
            jsonEncode({
              ...display,
              if (sceneGeometry['rootLinearRgb'] != null)
                'rootLinearRgb': sceneGeometry['rootLinearRgb'],
            }),
          );
        }
        expect(
          (display['triangles'] as List).length ~/ 3,
          lessThanOrEqualTo(250000),
        );
        // Numeric development discovery only: never print source identity/name.
        previousDebugPrint(
          '[viewport-discovery] bounds=${display['bounds']} triangles=${(display['triangles'] as List).length ~/ 3} edges=${(display['topologicalEdges'] as List).length} deflection=${display['displayDeflection']} angle=${display['displayAngle']}',
        );
        final refs = entity.data['managedStepAssets'] as Map;
        final publication = controller.runtime.managedImportPublication;
        expect(publication, isNotNull);
        expect(publication!.session, controller.runtime.sessionIdentity);
        expect(publication.revision, controller.runtime.runtimeRevision);
        expect(publication.bounds.minX, lessThan(publication.bounds.maxX));
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
