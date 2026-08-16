import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/import_export/import_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Professional CAD Import Export', () {
    late Directory project;
    late _Kernel kernel;
    late ImportExportApi api;
    setUp(() async {
      project = await Directory.systemTemp.createTemp('b001c_');
      kernel = _Kernel();
      api = ImportExportApi(
        kernel: kernel,
        repository: const ImportExportRepository(),
      );
    });
    tearDown(() => project.delete(recursive: true));

    test('STL binary or ASCII routes only through native mesh API', () async {
      final source = File('${project.path}${Platform.pathSeparator}part.stl')
        ..writeAsBytesSync([1, 2, 3]);
      final document = await api.import(
        CadImportRequest(
          projectId: 'p',
          projectDirectory: project,
          source: source,
          format: CadImportFormat.stl,
        ),
      );
      expect(document.mesh?.triangleCount, 1);
      expect(kernel.stlImports, 1);
      expect(api.documents, hasLength(1));
    });

    test('STEP and IGES import, validate and persist Project First', () async {
      for (final value in [
        (CadImportFormat.step, 'part.step'),
        (CadImportFormat.iges, 'part.igs'),
      ]) {
        final source = File(
          '${project.path}${Platform.pathSeparator}${value.$2}',
        )..writeAsStringSync('kernel input');
        final document = await api.import(
          CadImportRequest(
            projectId: 'p',
            projectDirectory: project,
            source: source,
            format: value.$1,
          ),
        );
        expect(document.shape?.type, CADShapeType.solid);
      }
      for (final folder in ImportExportRepository.folders) {
        expect(
          Directory(
            '${project.path}${Platform.pathSeparator}${folder.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      expect(
        File(
          '${project.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}ImportHistory${Platform.pathSeparator}history.jsonl',
        ).readAsLinesSync(),
        hasLength(2),
      );
    });

    test('STEP IGES and genuine STL exports require valid BRep', () async {
      final shape = ShapeHandle.reference(
        persistentId: 'shape',
        kernelId: 'test',
        type: CADShapeType.solid,
      );
      for (final value in [
        (CadExportFormat.step, 'out.step'),
        (CadExportFormat.iges, 'out.iges'),
        (CadExportFormat.stl, 'out.stl'),
      ]) {
        final destination = File(
          '${project.path}${Platform.pathSeparator}${value.$2}',
        );
        final result = await api.export(
          CadExportRequest(
            projectId: 'p',
            projectDirectory: project,
            destination: destination,
            format: value.$1,
            shape: shape,
          ),
        );
        expect(File(result.destination).lengthSync(), greaterThan(0));
      }
      expect(kernel.shapeExports, 2);
      expect(kernel.meshExports, 1);
    });

    test('invalid files and invalid topology never reach output', () async {
      final shape = ShapeHandle.reference(
        persistentId: 'invalid',
        kernelId: 'test',
        type: CADShapeType.shell,
      );
      kernel.invalid = true;
      final destination = File(
        '${project.path}${Platform.pathSeparator}invalid.step',
      );
      await expectLater(
        api.export(
          CadExportRequest(
            projectId: 'p',
            projectDirectory: project,
            destination: destination,
            format: CadExportFormat.step,
            shape: shape,
          ),
        ),
        throwsStateError,
      );
      expect(destination.existsSync(), isFalse);
      await expectLater(
        api.import(
          CadImportRequest(
            projectId: 'p',
            projectDirectory: project,
            source: File('${project.path}${Platform.pathSeparator}missing.stl'),
            format: CadImportFormat.stl,
          ),
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test(
      'OBJ and PLY fail explicitly because kernel has no capability',
      () async {
        for (final value in [
          (CadImportFormat.obj, 'part.obj'),
          (CadImportFormat.ply, 'part.ply'),
        ]) {
          final source = File(
            '${project.path}${Platform.pathSeparator}${value.$2}',
          )..writeAsStringSync('real file bytes');
          await expectLater(
            api.import(
              CadImportRequest(
                projectId: 'p',
                projectDirectory: project,
                source: source,
                format: value.$1,
              ),
            ),
            throwsUnsupportedError,
          );
        }
      },
    );

    test('workspace requests fit, bounding box and validation', () async {
      final source = File('${project.path}${Platform.pathSeparator}part.stl')
        ..writeAsBytesSync([1]);
      final document = await api.import(
        CadImportRequest(
          projectId: 'p',
          projectDirectory: project,
          source: source,
          format: CadImportFormat.stl,
        ),
      );
      final viewport = ImportExportWorkspace(api).viewport(document);
      expect(viewport, containsPair('fitView', true));
      expect(viewport['boundingBox'], isNotNull);
    });
  });
}

class _Kernel implements InterchangeGeometryKernelAPI, MeshGeometryKernelAPI {
  int stlImports = 0, shapeExports = 0, meshExports = 0;
  bool invalid = false;
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'test',
    name: 'Test kernel contract',
    version: '1',
    capabilities: KernelCapabilities({
      KernelCapability.step,
      KernelCapability.iges,
      KernelCapability.meshing,
    }),
    vendor: 'test',
  );
  @override
  Future<KernelHealth> healthCheck() async =>
      KernelHealth(KernelHealthStatus.healthy, 'ready', DateTime(2026));
  @override
  Future<KernelMeshHandle> importStl(
    String path, {
    required String projectId,
    KernelImportFormat format = KernelImportFormat.autoDetect,
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) async {
    stlImports++;
    return const KernelMeshHandle(
      persistentId: 'mesh',
      kernelId: 'test',
      fingerprint: 'real-contract',
      vertexCount: 3,
      triangleCount: 1,
      bounds: KernelBounds(0, 0, 0, 1, 1, 0),
      hasNormals: true,
      metadata: {'backend': 'kernel'},
    );
  }

  @override
  Future<ShapeHandle> importFile(
    String path,
    KernelExchangeFormat format, {
    required String projectId,
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) async => ShapeHandle.reference(
    persistentId: 'shape-${format.name}',
    kernelId: 'test',
    type: CADShapeType.solid,
  );
  @override
  Future<void> exportFile(
    ShapeHandle handle,
    String path,
    KernelExchangeFormat format, {
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) async {
    shapeExports++;
    File(path).writeAsStringSync('ISO-10303 kernel output ${format.name}');
  }

  @override
  Future<List<GeometryDiagnostic>> diagnose(ShapeHandle handle) async => invalid
      ? const [
          GeometryDiagnostic(
            code: 'invalid-topology',
            message: 'Invalid topology',
            severity: 'error',
          ),
        ]
      : const [];
  @override
  Future<KernelMeshResult> mesh(
    ShapeHandle handle, {
    required String outputPath,
    required double deflection,
  }) async {
    meshExports++;
    File(outputPath).writeAsBytesSync([0, 1, 2, 3]);
    return KernelMeshResult(
      source: handle,
      vertexCount: 3,
      triangleCount: 1,
      payloadPath: outputPath,
    );
  }

  @override
  Future<void> closeMesh(KernelMeshHandle handle) async {}
  @override
  Future<KernelMeshGeometry> inspectMesh(KernelMeshHandle handle) async =>
      const KernelMeshGeometry(
        nodes: [0, 0, 0, 1, 0, 0, 0, 1, 0],
        triangles: [0, 1, 2],
      );
  @override
  Future<List<HealingProposal>> proposeHealing(ShapeHandle handle) async =>
      const [];
  @override
  Future<ShapeHandle> sew(
    List<ShapeHandle> faces, {
    required String projectId,
    required double tolerance,
  }) async => faces.first;
  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) async => ShapeHandle.reference(
    persistentId: persistentId,
    kernelId: 'test',
    type: expectedType,
  );
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      const [];
  @override
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  @override
  Future<void> unload() async {}
}
