import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/mesh_foundation/analytics/mesh_analytics.dart';
import 'package:flcad_mobile/core/mesh_foundation/commands/fel_mesh_commands.dart';
import 'package:flcad_mobile/core/mesh_foundation/integration/mesh_factory.dart';
import 'package:flcad_mobile/core/mesh_foundation/integration/mesh_studio.dart';
import 'package:flcad_mobile/core/mesh_foundation/history/mesh_history.dart';
import 'package:flcad_mobile/core/mesh_foundation/models/mesh_models.dart';
import 'package:flcad_mobile/core/mesh_foundation/repository/mesh_repository.dart';
import 'package:flcad_mobile/core/mesh_foundation/runtime/mesh_runtime.dart';
import 'package:flcad_mobile/core/mesh_foundation/validation/mesh_validation.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('flcad-mesh-'));
  tearDown(() => directory.deleteSync(recursive: true));
  MeshEntity entity() => MeshEntity(
    id: 'p:mesh:1',
    name: 'bearing.stl',
    sourceFile: 'bearing.stl',
    checksum: 'fnv1a64:1',
    fileSize: 10,
    kernelHandle: const KernelMeshHandle(
      persistentId: 'p:mesh:1',
      kernelId: 'opencascade',
      fingerprint: 'real',
      vertexCount: 3,
      triangleCount: 1,
      bounds: KernelBounds(0, 0, 0, 1, 1, 1),
      hasNormals: true,
      metadata: {},
    ),
    units: 'mm',
    orientation: 'source',
    importDate: DateTime.utc(2026),
    importTime: Duration.zero,
    kernelTime: Duration.zero,
    repositoryTime: Duration.zero,
    health: MeshHealth.healthy,
    validationStatus: 'validated',
  );
  test(
    'kernel IO exposes all official STL import formats',
    () => expect(KernelImportFormat.values.map((e) => e.name), [
      'stl',
      'asciiStl',
      'binaryStl',
      'autoDetect',
    ]),
  );
  test('mesh entity exposes professional metadata and valid bounds', () {
    final mesh = entity();
    expect(
      mesh.toJson().keys,
      containsAll([
        'checksum',
        'triangleCount',
        'vertexCount',
        'boundingBox',
        'kernelHandle',
        'health',
      ]),
    );
    expect(const MeshValidation().validate(mesh), isEmpty);
  });
  test(
    'repository rejects duplicate ids and persists every Project First path',
    () async {
      final repository = MeshRepository(directory), mesh = entity();
      repository.register(mesh);
      expect(() => repository.register(mesh), throwsStateError);
      repository.rename(mesh.id, 'renamed');
      expect(repository.cloneMetadata(mesh.id)['name'], 'renamed');
      await repository.persist(
        analytics: MeshAnalytics(),
        history: MeshHistory(),
        diagnostics: {mesh.id: []},
      );
      for (final path in MeshRepository.paths) {
        expect(
          Directory(
            '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
    },
  );
  test('invalid metadata produces explicit diagnostics', () {
    final mesh = entity();
    mesh.kernelHandle = const KernelMeshHandle(
      persistentId: 'p:mesh:1',
      kernelId: 'opencascade',
      fingerprint: 'real',
      vertexCount: 0,
      triangleCount: 0,
      bounds: KernelBounds(1, 1, 1, 0, 0, 0),
      hasNormals: false,
      metadata: {},
    );
    expect(
      const MeshValidation().validate(mesh).map((e) => e.code),
      containsAll([
        'empty-triangulation',
        'empty-vertices',
        'missing-normals',
        'invalid-bounds',
      ]),
    );
  });
  test('Studio FEL and bootstrap are passive', () {
    final api = const MeshFactory().create(
      projectDirectory: Directory('.'),
      kernel: UnavailableGeometryKernel(),
    );
    expect(const MeshStudio().panels, hasLength(4));
    expect(createMeshFelCommands(api).length, greaterThanOrEqualTo(100));
    EngineeringBootstrap.instance.initialize();
    expect(
      EngineeringBootstrap.instance.services.get<MeshRuntime>().isInitialized,
      isFalse,
    );
  });
}
