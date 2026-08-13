import '../../adaptive_surface/models/surface_geometry.dart';
import '../models/hybrid_surface_models.dart';

class PatchPlanner {
  const PatchPlanner();
  List<PatchPlan> plan(
    List<HybridRegion> regions,
    List<SurfaceNetworkNode> nodes,
  ) {
    final result = <PatchPlan>[];
    for (final region in regions) {
      final kinds = nodes
              .where((e) => region.surfaceIds.contains(e.candidate.id))
              .map((e) => e.candidate.kind)
              .toSet(),
          kind =
              kinds.contains(SurfaceKind.patch) ||
                  kinds.contains(SurfaceKind.freeform)
              ? PatchPlanKind.patch
              : kinds.contains(SurfaceKind.blend)
              ? PatchPlanKind.blend
              : kinds.length > 1
              ? PatchPlanKind.transition
              : PatchPlanKind.extension;
      result.add(
        PatchPlan(
          id: 'patch-plan-${result.length + 1}',
          kind: kind,
          regionIds: region.regionIds,
          boundaryIds: nodes
              .where((e) => region.surfaceIds.contains(e.candidate.id))
              .expand((e) => e.sharedBoundaryIds)
              .toSet()
              .toList(),
          guideRequired:
              kind == PatchPlanKind.transition || kind == PatchPlanKind.patch,
          explanation:
              'Planned ${kind.name} region from hybrid classification and shared boundaries',
        ),
      );
    }
    return result;
  }
}
