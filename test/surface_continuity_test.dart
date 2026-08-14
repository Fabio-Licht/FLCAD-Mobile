import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/surface_continuity/api/surface_continuity_api.dart';
import 'package:flcad_mobile/core/surface_continuity/commands/fel_surface_continuity_commands.dart';
import 'package:flcad_mobile/core/surface_continuity/engine/surface_continuity_engine.dart';
import 'package:flcad_mobile/core/surface_continuity/integration/surface_continuity_integration.dart';
import 'package:flcad_mobile/core/surface_continuity/integration/surface_quality_workspace.dart';
import 'package:flcad_mobile/core/surface_continuity/models/surface_continuity_models.dart';
import 'package:flcad_mobile/core/surface_continuity/repository/surface_continuity_repository.dart';
import 'package:flcad_mobile/core/surface_fitting/models/surface_fitting_models.dart';
import 'package:flcad_mobile/core/surface_topology/models/surface_topology_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('flcad-g010e-'));
  tearDown(() => directory.deleteSync(recursive: true));

  test(
    '100 analyses preserve native curvature, G2, quality and integration',
    () async {
      final kernel = _QualityKernel();
      final project = <String, dynamic>{};
      final dashboard = <String, dynamic>{};
      final session = <String, dynamic>{};
      final repository = SurfaceContinuityRepository(directory);
      final api = SurfaceContinuityApi(
        SurfaceContinuityEngine(
          kernel: kernel,
          repository: repository,
          integration: OfficialSurfaceContinuityIntegration(
            project: project,
            dashboard: dashboard,
            session: session,
          ),
        ),
      );
      final topology = _topology(adjacent: true);

      for (var i = 0; i < 100; i++) {
        final report = await api.run(topology);
        expect(report.patchQualities, hasLength(2));
        expect(report.continuity.single.level, ContinuityLevel.g2);
        expect(report.continuity.single.rms, 0);
        expect(report.graph.edges['patch:a'], contains('patch:b'));
        expect(report.patchQualities.first.curvature.gaussian, .01);
        expect(
          report.patchQualities.first.zebra.toJson()['source'],
          'native surface normals',
        );
        expect(report.patchQualities.first.draft.approved, 80);
        expect(report.patchQualities.first.overall, inInclusiveRange(0, 1));
        expect(
          report.patchQualities.first.toJson()['geometryModified'],
          isFalse,
        );
      }

      expect(kernel.calls, 200);
      expect(repository.reports, hasLength(100));
      expect(project['surfaceQuality'], isNotNull);
      expect(project['engineeringStudio'], isNotNull);
      expect(project['interactiveReverse'], isNotNull);
      expect(project['liveValidation'], isNotNull);
      expect(project['engineeringIntelligence'], isNotNull);
      expect(dashboard['surfaceQuality'], isNotNull);
      expect(session['workflowStage'], 'surfaceQuality');
      await api.persist();
      for (final path in SurfaceContinuityRepository.paths) {
        expect(
          Directory(
            '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      final report = repository.reports.values.last;
      final workspace = SurfaceQualityWorkspace(report)..select('patch:a');
      expect(workspace.propertyInspector['Surface Health'], isNotNull);
      expect(workspace.panels, hasLength(9));
      expect(
        createSurfaceContinuityFelCommands(api, () => topology).length,
        greaterThanOrEqualTo(190),
      );
    },
  );

  test('isolated patch reports continuity as not applicable', () async {
    final repository = SurfaceContinuityRepository(directory);
    final report = await SurfaceContinuityApi(
      SurfaceContinuityEngine(kernel: _QualityKernel(), repository: repository),
    ).run(_topology(adjacent: false));
    expect(report.continuity.single.level, ContinuityLevel.notApplicable);
    expect(report.patchQualities.single.continuityScore, .5);
  });
}

SurfaceTopologyReport _topology({required bool adjacent}) {
  PatchEntity patch(String suffix, List<String> neighbors) => PatchEntity(
    id: 'patch:$suffix',
    surface: _surface(suffix),
    boundaryIds: const [],
    loopIds: const [],
    adjacentPatchIds: neighbors,
    intersectionIds: adjacent ? const ['intersection:ab'] : const [],
    recognitionRegionId: 'region:$suffix',
    confidence: .95,
    health: TopologyHealth.healthy,
    status: 'valid',
  );
  final patches = adjacent
      ? [
          patch('a', const ['patch:b']),
          patch('b', const ['patch:a']),
        ]
      : [patch('a', const [])];
  return SurfaceTopologyReport(
    id: adjacent ? 'topology:adjacent' : 'topology:isolated',
    surfaceFittingReportId: 'fitting:fixture',
    patches: patches,
    boundaries: const [],
    loops: const [],
    intersections: adjacent
        ? const [
            IntersectionEntity(
              id: 'intersection:ab',
              firstSurfaceId: 'surface:a',
              secondSurfaceId: 'surface:b',
              type: 'curve',
              length: 1,
              edgeCount: 1,
              quality: 1,
            ),
          ]
        : const [],
    graph: SurfaceTopologyGraph(
      {for (final p in patches) p.id: 'patch'},
      {for (final p in patches) p.id: p.adjacentPatchIds.toSet()},
    ),
    analytics: SurfaceTopologyAnalytics(
      elapsed: Duration.zero,
      patchCount: patches.length,
      boundaryCount: 0,
      loopCount: 0,
      intersectionCount: adjacent ? 1 : 0,
      adjacencyCount: adjacent ? 1 : 0,
      validCount: patches.length,
      invalidCount: 0,
      averageConfidence: .95,
    ),
    advice: const [],
    createdAt: DateTime.utc(2026),
  );
}

SurfaceEntity _surface(String suffix) => SurfaceEntity(
  id: 'surface:$suffix',
  recognitionRegionId: 'region:$suffix',
  primitiveType: PrimitiveType.plane,
  handle: ShapeHandle.reference(
    persistentId: 'handle:$suffix',
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

class _QualityKernel implements SurfaceQualityKernelAPI {
  int calls = 0;
  @override
  Future<Map<String, dynamic>> inspectSurfaceQuality(
    ShapeHandle surface, {
    required List<double> draftDirection,
    int samples = 100,
  }) async {
    calls++;
    return const {
      'minimumCurvature': .1,
      'maximumCurvature': .1,
      'averageMinimumCurvature': .1,
      'averageMaximumCurvature': .1,
      'meanCurvature': .1,
      'gaussianCurvature': .01,
      'curvatureGradient': 0.0,
      'curvatureStability': 1.0,
      'averageNormal': [0.0, 0.0, 1.0],
      'reflectionScore': .9,
      'zebra': {'horizontal': .8, 'vertical': .7, 'radial': .6, 'free': .5},
      'draft': {
        'minimumAngle': -10.0,
        'maximumAngle': 90.0,
        'negative': 10,
        'critical': 10,
        'approved': 80,
      },
    };
  }
}
