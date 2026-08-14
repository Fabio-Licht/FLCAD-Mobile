import 'dart:io';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/live_reconstruction/commands/fel_live_reconstruction_commands.dart';
import 'package:flcad_mobile/core/live_reconstruction/integration/live_reconstruction_factory.dart';
import 'package:flcad_mobile/core/live_reconstruction/integration/live_reconstruction_integration.dart';
import 'package:flcad_mobile/core/live_reconstruction/integration/reconstruction_workspace.dart';
import 'package:flcad_mobile/core/live_reconstruction/models/live_reconstruction_models.dart';
import 'package:flcad_mobile/core/live_reconstruction/repository/live_reconstruction_repository.dart';
import 'package:flcad_mobile/core/surface_continuity/models/surface_continuity_models.dart';
import 'package:flcad_mobile/core/surface_fitting/models/surface_fitting_models.dart';
import 'package:flcad_mobile/core/surface_operations/integration/surface_operations_factory.dart';
import 'package:flcad_mobile/core/surface_operations/models/surface_operation_models.dart';
import 'package:flcad_mobile/core/surface_topology/models/surface_topology_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('flcad-g010g-'));
  tearDown(() => directory.deleteSync(recursive: true));

  test(
    '100 pipelines update only affected objects and rollback deterministically',
    () async {
      final kernel = _Kernel();
      final operations = const SurfaceOperationsFactory().create(
        projectDirectory: directory,
        kernel: kernel,
      );
      final project = <String, dynamic>{},
          workflow = <String, dynamic>{},
          session = <String, dynamic>{},
          studio = <String, dynamic>{},
          intelligence = <String, dynamic>{},
          validation = <String, dynamic>{};
      final api = const LiveReconstructionFactory().create(
        projectDirectory: directory,
        operations: operations,
        integration: OfficialLiveReconstructionIntegration(
          project: project,
          workflow: workflow,
          session: session,
          studio: studio,
          intelligence: intelligence,
          liveValidation: validation,
        ),
      );
      final topology = _topology(), quality = _quality(topology);
      for (var i = 0; i < 100; i++) {
        var operation = operations.begin(
          type: SurfaceOperationType.moveBoundary,
          patch: topology.patches.first,
          parameters: {'distance': i.toDouble()},
        );
        operation = operations.preview(operation.id, topology, quality);
        operation = operations.validate(operation.id, topology, quality);
        var live = api.begin(operation, topology, quality);
        live = api.preview(live.id, quality);
        expect(live.preview?.affected.patches, {'patch:a'});
        expect(
          live.preview?.affected.patches,
          isNot(contains('patch:unrelated')),
        );
        expect(live.preview?.toJson()['fullProjectRecalculation'], isFalse);
        live = api.validate(live.id);
        expect(live.validation?.valid, isTrue);
        live = api.update(live.id);
        expect(live.updatedObjects, isNotEmpty);
        expect(
          live.updatedObjects.any((e) => e.contains('unrelated')),
          isFalse,
        );
        live = await api.commit(
          live.id,
          projectId: 'fixture',
          quality: quality,
        );
        expect(live.state, ReconstructionState.committed);
        live = await api.rollback(live.id);
        expect(live.state, ReconstructionState.rolledBack);
        expect(live.updatedObjects, isEmpty);
      }
      expect(api.engine.analytics.pipelines, 100);
      expect(api.engine.analytics.updates, 100);
      expect(api.engine.analytics.rollbacks, 100);
      expect(api.engine.analytics.commits, 100);
      expect(kernel.commits, 100);
      expect(kernel.rollbacks, 100);
      expect(project['liveReconstruction'], isNotNull);
      expect(workflow['liveReconstructionState'], 'rolledBack');
      expect(studio['liveReconstructionWorkspace'], isTrue);
      expect(intelligence['automaticActions'], isFalse);
      expect(validation['dirtyObjects'], isNotNull);
      final workspace = ReconstructionWorkspace(api.reconstructions.last);
      expect(workspace.panels, hasLength(7));
      expect(workspace.propertyInspector['Pipeline State'], 'rolledBack');
      expect(
        createLiveReconstructionFelCommands(
          api,
          () => operations.operations.lastOrNull,
          () => topology,
          () => quality,
        ).length,
        greaterThanOrEqualTo(250),
      );
      await api.persist();
      for (final path in LiveReconstructionRepository.paths) {
        expect(
          Directory(
            '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
    },
  );

  test('cancel restores preview state without committing geometry', () {
    final kernel = _Kernel(),
        operations = const SurfaceOperationsFactory().create(
          projectDirectory: directory,
          kernel: kernel,
        );
    final api = const LiveReconstructionFactory().create(
      projectDirectory: directory,
      operations: operations,
    );
    final topology = _topology(), quality = _quality(topology);
    var operation = operations.begin(
      type: SurfaceOperationType.trimSurface,
      patch: topology.patches.first,
    );
    operation = operations.preview(operation.id, topology, quality);
    operation = operations.validate(operation.id, topology, quality);
    var live = api.begin(operation, topology, quality);
    live = api.preview(live.id, quality);
    live = api.validate(live.id);
    live = api.update(live.id);
    live = api.cancel(live.id);
    expect(live.state, ReconstructionState.cancelled);
    expect(live.updatedObjects, isEmpty);
    expect(kernel.commits, 0);
  });

  test('unsupported kernel is propagated without geometry', () async {
    final operations = const SurfaceOperationsFactory().create(
      projectDirectory: directory,
      kernel: _UnsupportedKernel(),
    );
    final api = const LiveReconstructionFactory().create(
      projectDirectory: directory,
      operations: operations,
    );
    final topology = _topology(), quality = _quality(topology);
    var operation = operations.begin(
      type: SurfaceOperationType.moveBoundary,
      patch: topology.patches.first,
    );
    operation = operations.preview(operation.id, topology, quality);
    operation = operations.validate(operation.id, topology, quality);
    var live = api.begin(operation, topology, quality);
    live = api.preview(live.id, quality);
    live = api.validate(live.id);
    live = api.update(live.id);
    live = await api.commit(live.id, projectId: 'fixture', quality: quality);
    expect(live.state, ReconstructionState.unsupported);
    expect(live.operation.resultSurface, isNull);
    expect(live.operation.diagnostic, 'UnsupportedOperation: moveBoundary');
  });
}

SurfaceTopologyReport _topology() {
  PatchEntity patch(String id) => PatchEntity(
    id: 'patch:$id',
    surface: _surface(id),
    boundaryIds: ['boundary:$id'],
    loopIds: ['loop:$id'],
    adjacentPatchIds: const [],
    intersectionIds: const [],
    recognitionRegionId: 'region:$id',
    confidence: .95,
    health: TopologyHealth.healthy,
    status: 'valid',
  );
  final patches = [patch('a'), patch('unrelated')];
  return SurfaceTopologyReport(
    id: 'topology:fixture',
    surfaceFittingReportId: 'fitting:fixture',
    patches: patches,
    boundaries: [
      for (final id in ['a', 'unrelated'])
        BoundaryEntity(
          id: 'boundary:$id',
          length: 1,
          type: BoundaryType.closed,
          connectedSurfaceIds: ['surface:$id'],
          confidence: 1,
          health: TopologyHealth.healthy,
          nativeIndex: 0,
        ),
    ],
    loops: [
      for (final id in ['a', 'unrelated'])
        LoopEntity(
          id: 'loop:$id',
          surfaceId: 'surface:$id',
          boundaryIds: ['boundary:$id'],
          type: LoopType.closed,
          closed: true,
          health: TopologyHealth.healthy,
        ),
    ],
    intersections: const [],
    graph: const SurfaceTopologyGraph(
      {'patch:a': 'patch', 'patch:unrelated': 'patch'},
      {'patch:a': {}, 'patch:unrelated': {}},
    ),
    analytics: const SurfaceTopologyAnalytics(
      elapsed: Duration.zero,
      patchCount: 2,
      boundaryCount: 2,
      loopCount: 2,
      intersectionCount: 0,
      adjacencyCount: 0,
      validCount: 2,
      invalidCount: 0,
      averageConfidence: .95,
    ),
    advice: const [],
    createdAt: DateTime.utc(2026),
  );
}

SurfaceEntity _surface(String id) => SurfaceEntity(
  id: 'surface:$id',
  recognitionRegionId: 'region:$id',
  primitiveType: PrimitiveType.plane,
  handle: ShapeHandle.reference(
    persistentId: 'handle:$id',
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
  PatchQuality item(PatchEntity patch) => PatchQuality(
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
  final continuity = [
    for (final p in topology.patches)
      ContinuityAssessment(
        id: 'continuity:${p.id}:na',
        firstPatchId: p.id,
        secondPatchId: p.id,
        discontinuity: 0,
        angle: 0,
        maximumError: 0,
        meanError: 0,
        rms: 0,
        effective: 0,
        level: ContinuityLevel.notApplicable,
        classification: 'isolated',
      ),
  ];
  return SurfaceQualityReport(
    id: 'quality:fixture',
    topologyReportId: topology.id,
    patchQualities: topology.patches.map(item).toList(),
    continuity: continuity,
    graph: const ContinuityGraph(
      {'patch:a': {}, 'patch:unrelated': {}},
      {'patch:a': {}, 'patch:unrelated': {}},
    ),
    analytics: const SurfaceQualityAnalytics(
      elapsed: Duration.zero,
      patchCount: 2,
      continuityDistribution: {ContinuityLevel.notApplicable: 2},
      averageCurvature: 0,
      reflectionScore: 1,
      draftScore: 1,
      qualityScore: .9,
    ),
    advice: const [],
    createdAt: DateTime.utc(2026),
  );
}

class _Kernel implements SurfaceOperationKernelAPI {
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
      diagnostic: 'committed',
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
