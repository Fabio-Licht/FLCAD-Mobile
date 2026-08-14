import 'dart:io';
import 'dart:math' as math;

import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/mesh_foundation/models/mesh_models.dart';
import 'package:flcad_mobile/core/surface_fitting/api/surface_fitting_api.dart';
import 'package:flcad_mobile/core/surface_fitting/commands/fel_surface_fitting_commands.dart';
import 'package:flcad_mobile/core/surface_fitting/engine/surface_fitting_engine.dart';
import 'package:flcad_mobile/core/surface_fitting/fitters/primitive_surface_fitters.dart';
import 'package:flcad_mobile/core/surface_fitting/integration/surface_fitting_integration.dart';
import 'package:flcad_mobile/core/surface_fitting/integration/surface_fitting_workspace.dart';
import 'package:flcad_mobile/core/surface_fitting/repository/surface_fitting_repository.dart';
import 'package:flcad_mobile/core/surface_recognition/models/surface_recognition_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('flcad-g010c-'));
  tearDown(() => directory.deleteSync(recursive: true));
  final fixtures = <ProfessionalSurfaceFitter, List<Vector3>>{
    const PlaneSurfaceFitter(): [
      for (var y = 0; y < 10; y++)
        for (var x = 0; x < 10; x++) Vector3(x.toDouble(), y.toDouble(), 2),
    ],
    const CylinderSurfaceFitter(): [
      for (var z = 0; z < 5; z++)
        for (var a = 0; a < 24; a++)
          Vector3(
            3 * math.cos(a * math.pi / 12),
            3 * math.sin(a * math.pi / 12),
            z.toDouble(),
          ),
    ],
    const ConeSurfaceFitter(): [
      for (var z = 1; z < 6; z++)
        for (var a = 0; a < 24; a++)
          Vector3(
            z * .2 * math.cos(a * math.pi / 12),
            z * .2 * math.sin(a * math.pi / 12),
            z.toDouble(),
          ),
    ],
    const SphereSurfaceFitter(): [
      for (var p = 1; p < 8; p++)
        for (var a = 0; a < 16; a++)
          Vector3(
            4 * math.sin(p * math.pi / 8) * math.cos(a * math.pi / 8),
            4 * math.sin(p * math.pi / 8) * math.sin(a * math.pi / 8),
            4 * math.cos(p * math.pi / 8),
          ),
    ],
    const TorusSurfaceFitter(): [
      for (var u = 0; u < 16; u++)
        for (var v = 0; v < 8; v++)
          Vector3(
            (5 + math.cos(v * math.pi / 4)) * math.cos(u * math.pi / 8),
            (5 + math.cos(v * math.pi / 4)) * math.sin(u * math.pi / 8),
            math.sin(v * math.pi / 4),
          ),
    ],
  };

  test('100 deterministic fits for every professional primitive', () {
    for (final entry in fixtures.entries) {
      final classification = _classification(entry.key.type, entry.value);
      Map<String, dynamic>? baseline;
      for (var i = 0; i < 100; i++) {
        final fit = entry.key.fit(classification, entry.value),
            signature = {
              'parameters': fit.parameters,
              'residuals': fit.residuals.toJson(),
              'confidence': fit.confidence,
              'valid': fit.valid,
            };
        baseline ??= signature;
        expect(signature, baseline, reason: entry.key.type.name);
        expect(fit.valid, isTrue, reason: entry.key.type.name);
        expect(fit.residuals.rms, lessThan(1e-8), reason: entry.key.type.name);
      }
    }
  });

  test('100 complete pipelines create real kernel handles and reports', () async {
    final kernel = _FixtureKernel(fixtures[const CylinderSurfaceFitter()]!),
        project = <String, dynamic>{},
        dashboard = <String, dynamic>{},
        session = <String, dynamic>{};
    final repository = SurfaceFittingRepository(directory),
        api = SurfaceFittingApi(
          SurfaceFittingEngine(
            kernel: kernel,
            repository: repository,
            integration: OfficialSurfaceFittingIntegration(
              project: project,
              dashboard: dashboard,
              session: session,
            ),
          ),
        );
    final classification = _classification(
          PrimitiveType.cylinder,
          fixtures[const CylinderSurfaceFitter()]!,
        ),
        recognition = SurfaceRecognitionReport(
          id: 'recognition:fixture',
          meshId: 'mesh:fixture',
          classifications: [classification],
          graph: const RegionGraph({}),
          analytics: const RecognitionAnalytics(
            elapsed: Duration.zero,
            totalArea: 1,
            recognizedArea: 1,
            unknownArea: 0,
            averageConfidence: 1,
            distribution: {PrimitiveType.cylinder: 1},
          ),
          advice: const [],
          createdAt: DateTime.utc(2026),
        );
    for (var i = 0; i < 100; i++) {
      final report = await api.run(
        mesh: _mesh(kernel.geometry),
        recognition: recognition,
        projectId: 'fixture',
      );
      expect(report.surfaces.single.handle, isNotNull);
      expect(report.surfaces.single.handle!.kernelId, 'fixture-kernel');
      expect(report.analytics.accepted, 1);
      final workspace = SurfaceFittingWorkspace(report)
        ..select(report.surfaces.single.id);
      expect(workspace.propertyInspector['Surface Type'], 'cylinder');
    }
    expect(kernel.operations, everyElement('GENERATE CYLINDER'));
    expect(repository.reports.length, 100);
    expect(project['surfaceRepositoryUpdated'], isTrue);
    expect(dashboard['surfaceFitting'], isNotNull);
    expect(session['workflowStage'], 'surfaceFitting');
    await api.persist();
    for (final path in SurfaceFittingRepository.paths) {
      expect(
        Directory(
          '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
        ).existsSync(),
        isTrue,
      );
    }
    expect(
      createSurfaceFittingFelCommands(
        api,
        () => _mesh(kernel.geometry),
        () => recognition,
      ),
      hasLength(greaterThanOrEqualTo(150)),
    );
  });
}

SurfaceClassification _classification(
  PrimitiveType type,
  List<Vector3> points,
) {
  final parameters = switch (type) {
    PrimitiveType.plane => {
      'origin': [0, 0, 2],
      'normal': [0, 0, 1],
    },
    PrimitiveType.cylinder => {
      'origin': [0, 0, 0],
      'axis': [0, 0, 1],
      'radius': 3,
    },
    PrimitiveType.cone => {
      'apex': [0, 0, 0],
      'axis': [0, 0, 1],
      'angle': math.atan(.2),
    },
    PrimitiveType.sphere => {
      'center': [0, 0, 0],
      'radius': 4,
    },
    PrimitiveType.torus => {
      'center': [0, 0, 0],
      'axis': [0, 0, 1],
      'majorRadius': 5,
      'minorRadius': 1,
    },
    _ => const <String, dynamic>{},
  };
  final bounds = _bounds(points),
      region = SurfaceRegion(
        id: 'region:${type.name}',
        color: '#123456',
        triangleIndices: List.generate(
          math.max(8, points.length - 2),
          (i) => i,
        ),
        vertexIndices: List.generate(points.length, (i) => i),
        area: 100,
        averageNormal: const Vector3(0, 0, 1),
        bounds: bounds,
        meanCurvature: 0,
        confidence: 1,
        health: RecognitionHealth.excellent,
      );
  return SurfaceClassification(
    region: region,
    type: type,
    confidence: 1,
    quality: 1,
    parameters: parameters,
    evidence: const ['fixture'],
    reason: 'exact fixture',
    rms: 0,
  );
}

KernelBounds _bounds(List<Vector3> p) {
  var minX = p.first.x,
      minY = p.first.y,
      minZ = p.first.z,
      maxX = minX,
      maxY = minY,
      maxZ = minZ;
  for (final v in p) {
    minX = math.min(minX, v.x);
    minY = math.min(minY, v.y);
    minZ = math.min(minZ, v.z);
    maxX = math.max(maxX, v.x);
    maxY = math.max(maxY, v.y);
    maxZ = math.max(maxZ, v.z);
  }
  return KernelBounds(minX, minY, minZ, maxX, maxY, maxZ);
}

MeshEntity _mesh(KernelMeshGeometry geometry) => MeshEntity(
  id: 'mesh:fixture',
  name: 'fixture',
  sourceFile: 'fixture.stl',
  checksum: 'fixture',
  fileSize: 1,
  kernelHandle: KernelMeshHandle(
    persistentId: 'mesh-native',
    kernelId: 'fixture-kernel',
    fingerprint: 'fixture',
    vertexCount: geometry.nodes.length ~/ 3,
    triangleCount: geometry.triangles.length ~/ 3,
    bounds: const KernelBounds(-3, -3, 0, 3, 3, 4),
    hasNormals: true,
    metadata: const {},
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

class _FixtureKernel implements GeometryKernelAPI, MeshGeometryKernelAPI {
  _FixtureKernel(List<Vector3> points)
    : geometry = KernelMeshGeometry(
        nodes: [
          for (final p in points) ...[p.x, p.y, p.z],
        ],
        triangles: [
          for (var i = 2; i < points.length; i++) ...[0, i - 1, i],
        ],
      );
  final KernelMeshGeometry geometry;
  final operations = <String>[];
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'fixture-kernel',
    name: 'Fixture',
    version: '1',
    capabilities: KernelCapabilities({KernelCapability.cylinderSurface}),
    vendor: 'test',
  );
  @override
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) async {
    operations.add(operation);
    return ShapeHandle.reference(
      persistentId: persistentId,
      kernelId: descriptor.id,
      type: expectedType,
      fingerprint: 'native:$persistentId',
    );
  }

  @override
  Future<KernelHealth> healthCheck() async =>
      KernelHealth(KernelHealthStatus.healthy, 'ready', DateTime.now());
  @override
  Future<KernelMeshGeometry> inspectMesh(KernelMeshHandle handle) async =>
      geometry;
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      const [];
  @override
  Future<void> unload() async {}
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
