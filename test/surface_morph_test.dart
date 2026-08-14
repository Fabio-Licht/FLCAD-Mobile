import 'dart:io';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/live_reconstruction/integration/live_reconstruction_factory.dart';
import 'package:flcad_mobile/core/surface_continuity/models/surface_continuity_models.dart';
import 'package:flcad_mobile/core/surface_fitting/models/surface_fitting_models.dart';
import 'package:flcad_mobile/core/surface_morph/commands/fel_surface_morph_commands.dart';
import 'package:flcad_mobile/core/surface_morph/integration/surface_morph_factory.dart';
import 'package:flcad_mobile/core/surface_morph/integration/surface_morph_integration.dart';
import 'package:flcad_mobile/core/surface_morph/models/surface_morph_models.dart';
import 'package:flcad_mobile/core/surface_morph/repository/surface_morph_repository.dart';
import 'package:flcad_mobile/core/surface_morph/workspace/surface_morph_workspace.dart';
import 'package:flcad_mobile/core/surface_operations/integration/surface_operations_factory.dart';
import 'package:flcad_mobile/core/surface_operations/models/surface_operation_models.dart';
import 'package:flcad_mobile/core/surface_topology/models/surface_topology_models.dart';
import 'package:flcad_mobile/core/surface_extend/integration/surface_extend_factory.dart';
import 'package:flcad_mobile/core/surface_extend/models/surface_extend_models.dart';
import 'package:flcad_mobile/core/surface_extend/commands/fel_surface_extend_commands.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('flcad-g011a-'));
  tearDown(() => directory.deleteSync(recursive: true));
  test(
    '100 morph sessions preserve preview and complete supported rollback pipelines',
    () async {
      final kernel = _Kernel(),
          operations = const SurfaceOperationsFactory().create(
            projectDirectory: directory,
            kernel: kernel,
          ),
          live = const LiveReconstructionFactory().create(
            projectDirectory: directory,
            operations: operations,
          );
      final project = <String, dynamic>{},
          workflow = <String, dynamic>{},
          session = <String, dynamic>{},
          studio = <String, dynamic>{},
          intelligence = <String, dynamic>{};
      final api = const SurfaceMorphFactory().create(
        projectDirectory: directory,
        operations: operations,
        reconstruction: live,
        integration: OfficialSurfaceMorphIntegration(
          project: project,
          workflow: workflow,
          session: session,
          studio: studio,
          intelligence: intelligence,
        ),
      );
      final topology = _topology(), quality = _quality(topology);
      for (var i = 0; i < 100; i++) {
        var morph = api.begin(
          tool: MorphTool.move,
          patch: topology.patches.single,
          anchors: [
            MorphAnchor(
              id: 'fixed:$i',
              type: AnchorType.fixed,
              targetId: 'patch:a',
              position: const [0, 0, 0],
            ),
            MorphAnchor(
              id: 'soft:$i',
              type: AnchorType.soft,
              targetId: 'patch:a',
              position: const [1, 0, 0],
              strength: .5,
            ),
          ],
          radius: 10,
          falloff: FalloffType.gaussian,
        );
        morph = api.preview(morph.id, topology, quality);
        expect(
          morph.preview?.originalSurfaceId,
          topology.patches.single.surface.handle?.persistentId,
        );
        expect(morph.preview?.toJson()['geometryModified'], isFalse);
        expect(morph.preview?.influence.weights, hasLength(2));
        morph = api.validate(morph.id, topology, quality);
        expect(morph.validation?.valid, isTrue);
        morph = await api.commit(
          morph.id,
          topology: topology,
          quality: quality,
          projectId: 'fixture',
        );
        expect(morph.status, MorphStatus.committed);
        morph = await api.rollback(morph.id);
        expect(morph.status, MorphStatus.rolledBack);
      }
      expect(kernel.commits, 100);
      expect(kernel.rollbacks, 100);
      expect(api.engine.analytics.operations, 100);
      expect(api.engine.analytics.anchors, 200);
      expect(api.engine.analytics.rollbacks, 100);
      expect(project['surfaceMorph'], isNotNull);
      expect(workflow['surfaceMorphStatus'], 'rolledBack');
      expect(studio['surfaceMorphStudio'], isTrue);
      expect(intelligence['automaticActions'], isFalse);
      final workspace = SurfaceMorphWorkspace(api.sessions.last);
      expect(workspace.panels, hasLength(8));
      expect(workspace.propertyInspector['Anchor Count'], 2);
      expect(
        createSurfaceMorphFelCommands(
          api,
          () => topology,
          () => quality,
        ).length,
        greaterThanOrEqualTo(300),
      );
      await api.persist();
      for (final path in SurfaceMorphRepository.paths) {
        expect(
          Directory(
            '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
    },
  );
  test('conflicting boundary anchor blocks morph commit', () async {
    final kernel = _Kernel(),
        operations = const SurfaceOperationsFactory().create(
          projectDirectory: directory,
          kernel: kernel,
        ),
        live = const LiveReconstructionFactory().create(
          projectDirectory: directory,
          operations: operations,
        ),
        api = const SurfaceMorphFactory().create(
          projectDirectory: directory,
          operations: operations,
          reconstruction: live,
        );
    final topology = _topology(), quality = _quality(topology);
    var morph = api.begin(
      tool: MorphTool.move,
      patch: topology.patches.single,
      anchors: const [
        MorphAnchor(
          id: 'a',
          type: AnchorType.fixed,
          targetId: 'patch:a',
          position: [0, 0, 0],
        ),
      ],
      radius: 1,
      falloff: FalloffType.linear,
      constraintGroups: const [
        MorphConstraintGroup('g', 'locked', [
          SurfaceConstraint(
            id: 'lock',
            type: SurfaceConstraintType.lockedBoundary,
            targetId: 'boundary:a',
          ),
        ]),
      ],
    );
    morph = api.preview(morph.id, topology, quality);
    morph = api.validate(morph.id, topology, quality);
    expect(morph.status, MorphStatus.failed);
    expect(kernel.commits, 0);
  });
  test('unsupported backend is explicit and creates no geometry', () async {
    final operations = const SurfaceOperationsFactory().create(
          projectDirectory: directory,
          kernel: _Unsupported(),
        ),
        live = const LiveReconstructionFactory().create(
          projectDirectory: directory,
          operations: operations,
        ),
        api = const SurfaceMorphFactory().create(
          projectDirectory: directory,
          operations: operations,
          reconstruction: live,
        );
    final topology = _topology(), quality = _quality(topology);
    var morph = api.begin(
      tool: MorphTool.move,
      patch: topology.patches.single,
      anchors: const [
        MorphAnchor(
          id: 'a',
          type: AnchorType.fixed,
          targetId: 'patch:a',
          position: [0, 0, 0],
        ),
      ],
      radius: 1,
      falloff: FalloffType.smooth,
    );
    morph = api.preview(morph.id, topology, quality);
    morph = api.validate(morph.id, topology, quality);
    morph = await api.commit(
      morph.id,
      topology: topology,
      quality: quality,
      projectId: 'fixture',
    );
    expect(morph.status, MorphStatus.unsupported);
    expect(morph.diagnostic, 'UnsupportedOperation: moveBoundary');
  });

  test(
    '100 professional extend suites analyze preview validate and rollback',
    () async {
      final kernel = _Kernel(),
          operations = const SurfaceOperationsFactory().create(
            projectDirectory: directory,
            kernel: kernel,
          ),
          live = const LiveReconstructionFactory().create(
            projectDirectory: directory,
            operations: operations,
          ),
          morph = const SurfaceMorphFactory().create(
            projectDirectory: directory,
            operations: operations,
            reconstruction: live,
          ),
          api = const SurfaceExtendFactory().create(
            projectDirectory: directory,
            morph: morph,
          );
      final topology = _topology(),
          quality = _quality(topology),
          patch = topology.patches.single;
      const kinds = [
        ExtendType.distance,
        ExtendType.angle,
        ExtendType.vector,
        ExtendType.tangentG1,
        ExtendType.curvatureG2,
        ExtendType.manufacturing,
        ExtendType.smart,
      ];
      for (var i = 0; i < 100; i++) {
        for (final kind in kinds) {
          var value = api.begin(
            type: kind,
            patch: patch,
            boundaryId: patch.boundaryIds.single,
            anchors: [
              MorphAnchor(
                id: '${kind.name}:$i',
                type: AnchorType.boundary,
                targetId: patch.boundaryIds.single,
                position: const [0, 0, 0],
              ),
            ],
            parameters: {
              'distance': 1.0,
              'angle': 5.0,
              'vector': const [0.0, 0.0, 1.0],
            },
            manufacturingIntent: kind == ExtendType.manufacturing
                ? 'tooling'
                : '',
          );
          value = api.preview(value.id, topology, quality);
          expect(value.analysis?.toJson()['geometryModified'], isFalse);
          value = api.validate(value.id, topology, quality);
          expect(value.validation?.valid, isTrue);
          if (kind == ExtendType.distance) {
            value = await api.rollback(value.id);
            expect(value.status, ExtendStatus.rolledBack);
          }
        }
      }
      expect(api.sessions, hasLength(700));
      expect(api.engine.previews, 700);
      expect(api.engine.rollbacks, 100);
      expect(
        createSurfaceExtendFelCommands(
          api,
          () => topology,
          () => quality,
        ).length,
        greaterThanOrEqualTo(350),
      );
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
    persistentId: 'handle:a',
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
  final patch = topology.patches.single,
      item = PatchQuality(
        patch: topology.patches.single,
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
    patchQualities: [item],
    continuity: [
      ContinuityAssessment(
        id: 'continuity:a',
        firstPatchId: patch.id,
        secondPatchId: patch.id,
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

class _Unsupported implements SurfaceOperationKernelAPI {
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
