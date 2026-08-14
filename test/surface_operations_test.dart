import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/surface_continuity/models/surface_continuity_models.dart';
import 'package:flcad_mobile/core/surface_fitting/models/surface_fitting_models.dart';
import 'package:flcad_mobile/core/surface_operations/commands/fel_surface_operations_commands.dart';
import 'package:flcad_mobile/core/surface_operations/integration/surface_operations_factory.dart';
import 'package:flcad_mobile/core/surface_operations/integration/surface_operations_integration.dart';
import 'package:flcad_mobile/core/surface_operations/integration/surface_operations_workspace.dart';
import 'package:flcad_mobile/core/surface_operations/models/surface_operation_models.dart';
import 'package:flcad_mobile/core/surface_operations/repository/surface_operation_repository.dart';
import 'package:flcad_mobile/core/surface_topology/models/surface_topology_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('flcad-g010f-'));
  tearDown(() => directory.deleteSync(recursive: true));

  test(
    '100 deterministic transactional pipelines commit rollback and cancel',
    () async {
      final kernel = _OperationsKernel();
      final project = <String, dynamic>{},
          workflow = <String, dynamic>{},
          session = <String, dynamic>{},
          studio = <String, dynamic>{},
          intelligence = <String, dynamic>{},
          live = <String, dynamic>{};
      final api = const SurfaceOperationsFactory().create(
        projectDirectory: directory,
        kernel: kernel,
        integration: OfficialSurfaceOperationsIntegration(
          project: project,
          workflow: workflow,
          session: session,
          studio: studio,
          intelligence: intelligence,
          liveValidation: live,
        ),
      );
      final topology = _topology(), quality = _quality(topology);
      for (var i = 0; i < 100; i++) {
        var operation = api.begin(
          type: SurfaceOperationType.moveBoundary,
          patch: topology.patches.single,
          parameters: {'distance': i.toDouble()},
          constraints: [
            SurfaceConstraint(
              id: 'direction:$i',
              type: SurfaceConstraintType.direction,
              targetId: 'patch:a',
            ),
          ],
        );
        expect(
          operation.targetSurface,
          same(topology.patches.single.surface.handle),
        );
        operation = api.preview(operation.id, topology, quality);
        expect(operation.preview?.toJson()['geometryModified'], isFalse);
        operation = api.validate(operation.id, topology, quality);
        expect(operation.validation?.valid, isTrue);
        operation = await api.commit(
          operation.id,
          projectId: 'fixture',
          quality: quality,
        );
        expect(operation.status, SurfaceOperationStatus.committed);
        expect(operation.resultSurface, isNot(same(operation.targetSurface)));
        operation = await api.rollback(operation.id);
        expect(operation.status, SurfaceOperationStatus.rolledBack);

        var cancelled = api.begin(
          type: SurfaceOperationType.trimSurface,
          patch: topology.patches.single,
        );
        cancelled = api.preview(cancelled.id, topology, quality);
        cancelled = api.validate(cancelled.id, topology, quality);
        cancelled = api.cancel(cancelled.id);
        expect(cancelled.status, SurfaceOperationStatus.cancelled);
      }
      expect(kernel.commits, 100);
      expect(kernel.rollbacks, 100);
      expect(api.engine.analytics.commits, 100);
      expect(api.engine.analytics.rollbacks, 100);
      expect(api.engine.analytics.cancellations, 100);
      expect(api.operations, hasLength(200));
      expect(project['surfaceOperation'], isNotNull);
      expect(workflow['surfaceOperationStatus'], isNotNull);
      expect(session['history'], hasLength(greaterThan(100)));
      expect(studio['surfaceOperationsWorkspace'], isTrue);
      expect(intelligence['automaticActions'], isFalse);
      expect(live['surfaceOperationValidation'], isNotNull);
      final workspace = SurfaceOperationsWorkspace(api.operations.last);
      expect(workspace.panels, hasLength(7));
      expect(workspace.propertyInspector['Operation Type'], 'trimSurface');
      expect(
        createSurfaceOperationsFelCommands(
          api,
          () => topology,
          () => quality,
        ).length,
        greaterThanOrEqualTo(220),
      );
      await api.persist();
      for (final path in SurfaceOperationRepository.paths) {
        expect(
          Directory(
            '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
    },
  );

  test(
    'constraint conflict prohibits commit before GeometryKernelAPI',
    () async {
      final kernel = _OperationsKernel();
      final api = const SurfaceOperationsFactory().create(
        projectDirectory: directory,
        kernel: kernel,
      );
      final topology = _topology(), quality = _quality(topology);
      var operation = api.begin(
        type: SurfaceOperationType.moveBoundary,
        patch: topology.patches.single,
        constraints: const [
          SurfaceConstraint(
            id: 'lock:a',
            type: SurfaceConstraintType.lockedBoundary,
            targetId: 'boundary:a',
          ),
        ],
      );
      operation = api.preview(operation.id, topology, quality);
      operation = api.validate(operation.id, topology, quality);
      expect(operation.status, SurfaceOperationStatus.failed);
      expect(operation.validation?.constraintConflicts, isNotEmpty);
      await expectLater(
        api.commit(operation.id, projectId: 'fixture', quality: quality),
        throwsStateError,
      );
      expect(kernel.commits, 0);
    },
  );

  test(
    'unsupported backend returns explicit result without fake geometry',
    () async {
      final api = const SurfaceOperationsFactory().create(
        projectDirectory: directory,
        kernel: _UnsupportedKernel(),
      );
      final topology = _topology(), quality = _quality(topology);
      var operation = api.begin(
        type: SurfaceOperationType.moveBoundary,
        patch: topology.patches.single,
      );
      operation = api.preview(operation.id, topology, quality);
      operation = api.validate(operation.id, topology, quality);
      operation = await api.commit(
        operation.id,
        projectId: 'fixture',
        quality: quality,
      );
      expect(operation.status, SurfaceOperationStatus.unsupported);
      expect(operation.diagnostic, 'UnsupportedOperation: moveBoundary');
      expect(operation.resultSurface, isNull);
    },
  );
}

SurfaceTopologyReport _topology() {
  final patch = PatchEntity(
    id: 'patch:a',
    surface: _surface(),
    boundaryIds: const ['boundary:a'],
    loopIds: const ['loop:a'],
    adjacentPatchIds: const [],
    intersectionIds: const [],
    recognitionRegionId: 'region:a',
    confidence: .95,
    health: TopologyHealth.healthy,
    status: 'valid',
  );
  return SurfaceTopologyReport(
    id: 'topology:a',
    surfaceFittingReportId: 'fitting:a',
    patches: [patch],
    boundaries: const [
      BoundaryEntity(
        id: 'boundary:a',
        length: 1,
        type: BoundaryType.closed,
        connectedSurfaceIds: ['surface:a'],
        confidence: 1,
        health: TopologyHealth.healthy,
        nativeIndex: 0,
      ),
    ],
    loops: const [
      LoopEntity(
        id: 'loop:a',
        surfaceId: 'surface:a',
        boundaryIds: ['boundary:a'],
        type: LoopType.closed,
        closed: true,
        health: TopologyHealth.healthy,
      ),
    ],
    intersections: const [],
    graph: const SurfaceTopologyGraph({'patch:a': 'patch'}, {'patch:a': {}}),
    analytics: const SurfaceTopologyAnalytics(
      elapsed: Duration.zero,
      patchCount: 1,
      boundaryCount: 1,
      loopCount: 1,
      intersectionCount: 0,
      adjacencyCount: 0,
      validCount: 1,
      invalidCount: 0,
      averageConfidence: .95,
    ),
    advice: const [],
    createdAt: DateTime.utc(2026),
  );
}

SurfaceEntity _surface() => SurfaceEntity(
  id: 'surface:a',
  recognitionRegionId: 'region:a',
  primitiveType: PrimitiveType.plane,
  handle: ShapeHandle.reference(
    persistentId: 'surface-handle:a',
    kernelId: 'fixture',
    type: CADShapeType.face,
  ),
  bounds: const KernelBounds(0, 0, 0, 1, 1, 0),
  area: 1,
  parameters: const {},
  residuals: const ResidualStatistics(
    values: [0],
    rms: 0,
    maximum: 0,
    mean: 0,
    standardDeviation: 0,
    distribution: {'exact': 1},
  ),
  confidence: .95,
  health: SurfaceFitHealth.excellent,
  timestamp: DateTime.utc(2026),
  status: SurfaceFitStatus.accepted,
);

SurfaceQualityReport _quality(SurfaceTopologyReport topology) {
  final patch = topology.patches.single;
  final quality = PatchQuality(
    patch: patch,
    curvature: const CurvatureAnalysis(
      minimum: 0,
      maximum: 0,
      averageMinimum: 0,
      averageMaximum: 0,
      mean: 0,
      gaussian: 0,
      gradient: 0,
      stability: 1,
      equivalentRadius: double.infinity,
    ),
    reflection: const ReflectionAnalysis(
      lines: [1],
      environment: 1,
      flow: 1,
      quality: 1,
    ),
    zebra: const ZebraAnalysis(
      horizontal: 1,
      vertical: 1,
      radial: 1,
      free: 1,
      density: 12,
      contrast: 1,
    ),
    draft: const DraftAnalysis(
      direction: [0, 0, 1],
      minimumAngle: 90,
      maximumAngle: 90,
      negative: 0,
      critical: 0,
      approved: 100,
    ),
    continuityScore: .5,
    curvatureScore: 1,
    reflectionScore: 1,
    draftScore: 1,
    topologyScore: 1,
    recognitionConfidence: .95,
    surfaceConfidence: .95,
    overall: .9,
    health: SurfaceQualityHealth.excellent,
  );
  return SurfaceQualityReport(
    id: 'quality:a',
    topologyReportId: topology.id,
    patchQualities: [quality],
    continuity: [
      const ContinuityAssessment(
        id: 'continuity:a:na',
        firstPatchId: 'patch:a',
        secondPatchId: 'patch:a',
        discontinuity: 0,
        angle: 0,
        maximumError: 0,
        meanError: 0,
        rms: 0,
        effective: 0,
        level: ContinuityLevel.notApplicable,
        classification: 'isolated',
      ),
    ],
    graph: const ContinuityGraph({'patch:a': {}}, {'patch:a': {}}),
    analytics: const SurfaceQualityAnalytics(
      elapsed: Duration.zero,
      patchCount: 1,
      continuityDistribution: {ContinuityLevel.notApplicable: 1},
      averageCurvature: 0,
      reflectionScore: 1,
      draftScore: 1,
      qualityScore: .9,
    ),
    advice: const [],
    createdAt: DateTime.utc(2026),
  );
}

class _OperationsKernel implements SurfaceOperationKernelAPI {
  int commits = 0, rollbacks = 0;
  @override
  Future<KernelSurfaceOperationResult> executeSurfaceOperation(
    ShapeHandle surface,
    String operation,
    Map<String, dynamic> parameters, {
    required String projectId,
  }) async {
    commits++;
    return KernelSurfaceOperationResult(
      supported: true,
      diagnostic: 'OpenCascade operation completed',
      result: ShapeHandle.reference(
        persistentId: 'result:$commits',
        kernelId: 'fixture',
        type: CADShapeType.face,
      ),
      undoToken: 'undo:$commits',
      redoToken: 'redo:$commits',
    );
  }

  @override
  Future<void> rollbackSurfaceOperation(String undoToken) async => rollbacks++;
}

class _UnsupportedKernel implements SurfaceOperationKernelAPI {
  @override
  Future<KernelSurfaceOperationResult> executeSurfaceOperation(
    ShapeHandle surface,
    String operation,
    Map<String, dynamic> parameters, {
    required String projectId,
  }) async => KernelSurfaceOperationResult(
    supported: false,
    diagnostic: 'UnsupportedOperation: $operation',
  );
  @override
  Future<void> rollbackSurfaceOperation(String undoToken) async =>
      throw StateError('UnsupportedOperation');
}
