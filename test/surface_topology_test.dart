import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/surface_fitting/models/surface_fitting_models.dart';
import 'package:flcad_mobile/core/surface_topology/api/surface_topology_api.dart';
import 'package:flcad_mobile/core/surface_topology/commands/fel_surface_topology_commands.dart';
import 'package:flcad_mobile/core/surface_topology/engine/surface_topology_engine.dart';
import 'package:flcad_mobile/core/surface_topology/integration/surface_topology_integration.dart';
import 'package:flcad_mobile/core/surface_topology/integration/surface_topology_workspace.dart';
import 'package:flcad_mobile/core/surface_topology/repository/surface_topology_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('flcad-g010d-'));
  tearDown(() => directory.deleteSync(recursive: true));
  test(
    '100 topology builds preserve native boundaries loops intersections patches and graph',
    () async {
      final kernel = _TopologyKernel(),
          project = <String, dynamic>{},
          dashboard = <String, dynamic>{},
          session = <String, dynamic>{},
          repository = SurfaceTopologyRepository(directory),
          api = SurfaceTopologyApi(
            SurfaceTopologyEngine(
              kernel: kernel,
              repository: repository,
              integration: OfficialSurfaceTopologyIntegration(
                project: project,
                dashboard: dashboard,
                session: session,
              ),
            ),
          ),
          fitting = _fitting();
      Map<String, dynamic>? baseline;
      for (var i = 0; i < 100; i++) {
        final report = await api.build(fitting, projectId: 'fixture'),
            signature = {
              'patches': report.patches.map((e) => e.toJson()).toList(),
              'boundaries': report.boundaries.map((e) => e.toJson()).toList(),
              'loops': report.loops.map((e) => e.toJson()).toList(),
              'intersections': report.intersections
                  .map((e) => e.toJson())
                  .toList(),
              'graph': report.graph.toJson(),
            };
        baseline ??= signature;
        expect(signature, baseline);
        expect(report.patches, hasLength(2));
        expect(report.boundaries, hasLength(4));
        expect(report.loops, hasLength(2));
        expect(report.intersections.single.handle, isNotNull);
        expect(report.analytics.adjacencyCount, 1);
        final workspace = SurfaceTopologyWorkspace(report)
          ..selectPatch(report.patches.first.id);
        expect(workspace.propertyInspector['Boundary Count'], 2);
      }
      expect(kernel.topologyCalls, 200);
      expect(kernel.intersectionCalls, 100);
      expect(repository.reports, hasLength(100));
      expect(project['surfaceTopology'], isNotNull);
      expect(dashboard['surfaceTopology'], isNotNull);
      expect(session['workflowStage'], 'surfaceTopology');
      await api.persist();
      for (final path in SurfaceTopologyRepository.paths) {
        expect(
          Directory(
            '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      expect(
        createSurfaceTopologyFelCommands(api, () => fitting).length,
        greaterThanOrEqualTo(170),
      );
    },
  );
}

SurfaceFittingReport _fitting() {
  const stats = ResidualStatistics(
    values: [0],
    rms: 0,
    maximum: 0,
    mean: 0,
    standardDeviation: 0,
    distribution: {'0-1 RMS': 1},
  );
  SurfaceEntity surface(String id, PrimitiveType type) => SurfaceEntity(
    id: id,
    recognitionRegionId: 'region:$id',
    primitiveType: type,
    handle: ShapeHandle.reference(
      persistentId: 'handle:$id',
      kernelId: 'fixture',
      type: CADShapeType.face,
      fingerprint: id,
    ),
    bounds: const KernelBounds(0, 0, 0, 10, 10, 10),
    area: 100,
    parameters: const {},
    residuals: stats,
    confidence: .95,
    health: SurfaceFitHealth.excellent,
    timestamp: DateTime.utc(2026),
    status: SurfaceFitStatus.accepted,
  );
  return SurfaceFittingReport(
    id: 'fitting:fixture',
    recognitionReportId: 'recognition:fixture',
    surfaces: [
      surface('plane', PrimitiveType.plane),
      surface('cylinder', PrimitiveType.cylinder),
    ],
    analytics: const SurfaceFittingAnalytics(
      elapsed: Duration.zero,
      distribution: {PrimitiveType.plane: 1, PrimitiveType.cylinder: 1},
      averageRms: 0,
      averageResidual: 0,
      averageConfidence: .95,
      accepted: 2,
      rejected: 0,
    ),
    advice: const [],
    createdAt: DateTime.utc(2026),
  );
}

class _TopologyKernel implements SurfaceTopologyKernelAPI {
  int topologyCalls = 0, intersectionCalls = 0;
  @override
  Future<KernelSurfaceTopology> inspectSurfaceTopology(
    ShapeHandle surface,
  ) async {
    topologyCalls++;
    return const KernelSurfaceTopology(
      boundaries: [
        KernelBoundaryData(index: 0, length: 10, closed: false),
        KernelBoundaryData(index: 1, length: 20, closed: true),
      ],
      loops: [
        KernelLoopData(index: 0, closed: true, boundaryIndices: [0, 1]),
      ],
    );
  }

  @override
  Future<KernelSurfaceIntersection> intersectSurfaces(
    ShapeHandle first,
    ShapeHandle second, {
    required String projectId,
  }) async {
    intersectionCalls++;
    return KernelSurfaceIntersection(
      edgeCount: 1,
      length: 12,
      handle: ShapeHandle.reference(
        persistentId:
            'intersection:${first.persistentId}:${second.persistentId}',
        kernelId: 'fixture',
        type: CADShapeType.compound,
      ),
    );
  }
}
