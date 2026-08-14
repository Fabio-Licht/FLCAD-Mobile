import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/mesh_foundation/models/mesh_models.dart';
import 'package:flcad_mobile/core/surface_recognition/api/surface_recognition_api.dart';
import 'package:flcad_mobile/core/surface_recognition/classification/primitive_classifier.dart';
import 'package:flcad_mobile/core/surface_recognition/commands/fel_surface_recognition_commands.dart';
import 'package:flcad_mobile/core/surface_recognition/engine/surface_recognition_engine.dart';
import 'package:flcad_mobile/core/surface_recognition/integration/recognition_workspace.dart';
import 'package:flcad_mobile/core/surface_recognition/integration/surface_recognition_integration.dart';
import 'package:flcad_mobile/core/surface_recognition/models/surface_recognition_models.dart';
import 'package:flcad_mobile/core/surface_recognition/repository/surface_recognition_repository.dart';
import 'package:flcad_mobile/core/surface_recognition/segmentation/region_growing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('flcad-g010b-'));
  tearDown(() => directory.deleteSync(recursive: true));

  test(
    'region growing uses topology normals curvature and is deterministic',
    () {
      const data = MeshSurfaceData(
        vertices: [
          Vector3(0, 0, 0),
          Vector3(1, 0, 0),
          Vector3(1, 1, 0),
          Vector3(0, 1, 0),
          Vector3(0, 0, 1),
          Vector3(1, 0, 1),
        ],
        triangles: [(0, 1, 2), (0, 2, 3), (0, 1, 4)],
      );
      const engine = ProfessionalRegionGrowing();
      final a = engine.segment(
        data,
        'fixture',
        settings: const SurfaceRecognitionSettings(
          normalAngleDegrees: 10,
          curvatureDelta: 2,
          minimumTriangles: 1,
        ),
      );
      final b = engine.segment(
        data,
        'fixture',
        settings: const SurfaceRecognitionSettings(
          normalAngleDegrees: 10,
          curvatureDelta: 2,
          minimumTriangles: 1,
        ),
      );
      expect(a.regions.length, 2);
      expect(
        a.regions.map((e) => e.toJson()).toList(),
        b.regions.map((e) => e.toJson()).toList(),
      );
      expect(a.graph.edges.values.any((e) => e.isNotEmpty), isTrue);
    },
  );

  test('primitive classification uses fitted evidence and confidence', () {
    final points = [
      for (var y = 0; y < 10; y++)
        for (var x = 0; x < 10; x++) Vector3(x.toDouble(), y.toDouble(), 2),
    ];
    final triangles = <(int, int, int)>[];
    for (var y = 0; y < 9; y++) {
      for (var x = 0; x < 9; x++) {
        final a = y * 10 + x;
        triangles.add((a, a + 1, a + 10));
        triangles.add((a + 1, a + 11, a + 10));
      }
    }
    final data = MeshSurfaceData(vertices: points, triangles: triangles);
    final segmented = const ProfessionalRegionGrowing().segment(
      data,
      'plane',
      settings: const SurfaceRecognitionSettings(minimumTriangles: 1),
    );
    final result = const PrimitiveClassifier().classify(
      segmented.regions.single,
      data,
    );
    expect(result.type, PrimitiveType.plane);
    expect(result.evidence.length, greaterThanOrEqualTo(5));
    expect(result.confidence, inInclusiveRange(0, 1));
  });

  test(
    '100 complete executions preserve regions reports analytics and advice',
    () async {
      final kernel = _FixtureKernel(),
          project = <String, dynamic>{},
          dashboard = <String, dynamic>{},
          session = <String, dynamic>{};
      final repository = SurfaceRecognitionRepository(directory);
      final api = SurfaceRecognitionApi(
        SurfaceRecognitionEngine(
          kernel: kernel,
          repository: repository,
          integration: OfficialSurfaceRecognitionIntegration(
            project: project,
            dashboard: dashboard,
            session: session,
          ),
          settings: const SurfaceRecognitionSettings(minimumTriangles: 1),
        ),
      );
      final mesh = _mesh();
      List<Map<String, dynamic>>? baseline;
      for (var i = 0; i < 100; i++) {
        final report = await api.run(mesh);
        final signature = report.classifications
            .map((e) => e.toJson()..remove('confidence'))
            .toList();
        baseline ??= signature;
        expect(signature, baseline);
        expect(report.analytics.totalArea, greaterThan(0));
        expect(report.advice, isNotEmpty);
        final tree = RecognitionWorkspace(report);
        tree.select(report.classifications.first.region.id);
        expect(tree.propertyInspector['Recognition Type'], isNotNull);
      }
      expect(repository.reports.length, 100);
      expect(project['surfaceRecognition'], isNotNull);
      expect(dashboard['recognitionCompleted'], isTrue);
      expect(session['workflowStage'], 'recognition');
      await api.persist();
      for (final path in SurfaceRecognitionRepository.paths) {
        expect(
          Directory(
            '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      expect(
        createSurfaceRecognitionFelCommands(api, () => mesh).length,
        greaterThanOrEqualTo(120),
      );
    },
  );
}

MeshEntity _mesh() => MeshEntity(
  id: 'mesh:fixture',
  name: 'fixture',
  sourceFile: 'fixture.stl',
  checksum: 'fixture',
  fileSize: 1,
  kernelHandle: const KernelMeshHandle(
    persistentId: 'kernel:mesh',
    kernelId: 'fixture',
    fingerprint: 'fixture',
    vertexCount: 4,
    triangleCount: 2,
    bounds: KernelBounds(0, 0, 0, 1, 1, 0),
    hasNormals: true,
    metadata: {},
  ),
  units: 'mm',
  orientation: 'native',
  importDate: DateTime.utc(2026),
  importTime: Duration.zero,
  kernelTime: Duration.zero,
  repositoryTime: Duration.zero,
  health: MeshHealth.healthy,
  validationStatus: 'valid',
);

class _FixtureKernel implements MeshGeometryKernelAPI {
  @override
  Future<KernelMeshGeometry> inspectMesh(KernelMeshHandle handle) async =>
      const KernelMeshGeometry(
        nodes: [0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0],
        triangles: [0, 1, 2, 0, 2, 3],
      );
  @override
  Future<void> closeMesh(KernelMeshHandle handle) async {}
  @override
  Future<KernelMeshHandle> importStl(
    String path, {
    required String projectId,
    KernelImportFormat format = KernelImportFormat.autoDetect,
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) => throw UnimplementedError();
}
