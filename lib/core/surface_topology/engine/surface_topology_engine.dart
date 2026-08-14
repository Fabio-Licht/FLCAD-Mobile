import '../../cad_kernel/io/kernel_io_models.dart';
import '../../surface_fitting/models/surface_fitting_models.dart';
import '../../utils/id_generator.dart';
import '../advisor/topology_advisor.dart';
import '../integration/surface_topology_integration.dart';
import '../models/surface_topology_models.dart';
import '../repository/surface_topology_repository.dart';
import '../runtime/surface_topology_runtime.dart';
import '../validation/topology_validation.dart';

class SurfaceTopologyEngine {
  SurfaceTopologyEngine({
    required this.kernel,
    required this.repository,
    this.integration,
  });
  final SurfaceTopologyKernelAPI kernel;
  final SurfaceTopologyRepository repository;
  final SurfaceTopologyIntegration? integration;
  final advisor = const SurfaceTopologyAdvisor(),
      validation = const SurfaceTopologyValidation();
  Future<SurfaceTopologyReport> build(
    SurfaceFittingReport fitting, {
    required String projectId,
  }) async {
    await SurfaceTopologyRuntime.instance.initialize();
    final watch = Stopwatch()..start();
    final surfaces = fitting.surfaces
            .where(
              (e) => e.status == SurfaceFitStatus.accepted && e.handle != null,
            )
            .toList(),
        boundaries = <BoundaryEntity>[],
        loops = <LoopEntity>[],
        intersections = <IntersectionEntity>[],
        surfaceBoundary = <String, List<String>>{},
        surfaceLoop = <String, List<String>>{},
        neighbors = <String, Set<String>>{},
        surfaceIntersections = <String, List<String>>{};
    for (final surface in surfaces) {
      final topology = await kernel.inspectSurfaceTopology(surface.handle!);
      final ids = <String>[];
      for (final boundary in topology.boundaries) {
        final id = 'boundary:${surface.id}:${boundary.index}';
        ids.add(id);
        boundaries.add(
          BoundaryEntity(
            id: id,
            length: boundary.length,
            type: boundary.closed ? BoundaryType.closed : BoundaryType.open,
            connectedSurfaceIds: [surface.id],
            confidence: surface.confidence,
            health: boundary.length > 1e-9
                ? TopologyHealth.healthy
                : TopologyHealth.invalid,
            nativeIndex: boundary.index,
          ),
        );
      }
      surfaceBoundary[surface.id] = ids;
      final loopIds = <String>[];
      for (final loop in topology.loops) {
        final id = 'loop:${surface.id}:${loop.index}',
            boundaryIds = loop.boundaryIndices
                .map((i) => 'boundary:${surface.id}:$i')
                .toList(),
            length = boundaries
                .where((e) => boundaryIds.contains(e.id))
                .fold<double>(0, (s, e) => s + e.length),
            type = !loop.closed
                ? LoopType.open
                : loop.index == 0
                ? LoopType.outer
                : length < 1e-6
                ? LoopType.micro
                : LoopType.inner;
        loopIds.add(id);
        loops.add(
          LoopEntity(
            id: id,
            surfaceId: surface.id,
            boundaryIds: boundaryIds,
            type: type,
            closed: loop.closed,
            health: boundaryIds.isEmpty
                ? TopologyHealth.invalid
                : TopologyHealth.healthy,
          ),
        );
      }
      surfaceLoop[surface.id] = loopIds;
      neighbors[surface.id] = <String>{};
      surfaceIntersections[surface.id] = [];
    }
    for (var i = 0; i < surfaces.length; i++) {
      for (var j = i + 1; j < surfaces.length; j++) {
        final first = surfaces[i],
            second = surfaces[j],
            native = await kernel.intersectSurfaces(
              first.handle!,
              second.handle!,
              projectId: projectId,
            );
        if (native.edgeCount == 0) continue;
        final id = 'intersection:${first.id}:${second.id}';
        intersections.add(
          IntersectionEntity(
            id: id,
            firstSurfaceId: first.id,
            secondSurfaceId: second.id,
            type: '${first.primitiveType.name} × ${second.primitiveType.name}',
            length: native.length,
            edgeCount: native.edgeCount,
            quality: native.length > 1e-9 ? 1 : 0,
            handle: native.handle,
          ),
        );
        neighbors[first.id]!.add(second.id);
        neighbors[second.id]!.add(first.id);
        surfaceIntersections[first.id]!.add(id);
        surfaceIntersections[second.id]!.add(id);
      }
    }
    final patchIds = {for (final s in surfaces) s.id: 'patch:${s.id}'};
    final patches = [
      for (final surface in surfaces)
        PatchEntity(
          id: patchIds[surface.id]!,
          surface: surface,
          boundaryIds: surfaceBoundary[surface.id]!,
          loopIds: surfaceLoop[surface.id]!,
          adjacentPatchIds:
              neighbors[surface.id]!.map((e) => patchIds[e]!).toList()..sort(),
          intersectionIds: surfaceIntersections[surface.id]!,
          recognitionRegionId: surface.recognitionRegionId,
          confidence: surface.confidence,
          health: surfaceLoop[surface.id]!.isEmpty
              ? TopologyHealth.invalid
              : TopologyHealth.healthy,
          status: 'constructed',
        ),
    ];
    final nodes = <String, String>{}, edges = <String, Set<String>>{};
    void node(String id, String type) {
      nodes[id] = type;
      edges.putIfAbsent(id, () => {});
    }

    void connect(String a, String b) {
      edges[a]!.add(b);
      edges[b]!.add(a);
    }

    for (final patch in patches) {
      node(patch.surface.id, 'surface');
      node(patch.id, 'patch');
      connect(patch.surface.id, patch.id);
      for (final id in patch.boundaryIds) {
        node(id, 'boundary');
        connect(patch.id, id);
      }
      for (final id in patch.loopIds) {
        node(id, 'loop');
        connect(patch.id, id);
      }
      for (final id in patch.intersectionIds) {
        node(id, 'intersection');
        connect(patch.id, id);
      }
      for (final id in patch.adjacentPatchIds) {
        node(id, 'patch');
        connect(patch.id, id);
      }
    }
    for (final loop in loops) {
      for (final boundary in loop.boundaryIds) {
        connect(loop.id, boundary);
      }
    }
    watch.stop();
    final valid = patches
            .where((e) => e.health == TopologyHealth.healthy)
            .length,
        analytics = SurfaceTopologyAnalytics(
          elapsed: watch.elapsed,
          patchCount: patches.length,
          boundaryCount: boundaries.length,
          loopCount: loops.length,
          intersectionCount: intersections.length,
          adjacencyCount:
              neighbors.values.fold<int>(0, (s, e) => s + e.length) ~/ 2,
          validCount: valid,
          invalidCount: patches.length - valid,
          averageConfidence: patches.isEmpty
              ? 0
              : patches.fold<double>(0, (s, e) => s + e.confidence) /
                    patches.length,
        );
    final report = SurfaceTopologyReport(
      id: 'surface-topology:${IdGenerator.generate()}',
      surfaceFittingReportId: fitting.id,
      patches: patches,
      boundaries: boundaries,
      loops: loops,
      intersections: intersections,
      graph: SurfaceTopologyGraph(nodes, edges),
      analytics: analytics,
      advice: advisor.advise(patches, boundaries, loops),
      createdAt: DateTime.now().toUtc(),
    );
    final errors = validation.validate(report);
    if (errors.isNotEmpty) {
      throw StateError(errors.join('; '));
    }
    repository.save(report);
    integration?.onTopologyBuilt(report);
    return report;
  }
}
