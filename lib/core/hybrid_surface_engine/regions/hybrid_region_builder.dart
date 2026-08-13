import '../../adaptive_surface/models/surface_geometry.dart';
import '../models/hybrid_surface_models.dart';

class HybridRegionBuilder {
  const HybridRegionBuilder();
  List<HybridRegion> build(List<SurfaceNetworkNode> nodes) {
    final result = <HybridRegion>[], visited = <String>{};
    for (final node in nodes) {
      if (visited.contains(node.candidate.id)) continue;
      final group = nodes
          .where(
            (other) =>
                other.candidate.regionIds.any(
                  node.candidate.regionIds.contains,
                ) ||
                node.neighborIds.contains(other.candidate.id),
          )
          .toList();
      visited.addAll(group.map((e) => e.candidate.id));
      final kinds = group.map((e) => e.candidate.kind).toSet(),
          analytical = kinds.every(_analytical),
          hasFreeform = kinds.any(
            (e) =>
                e == SurfaceKind.nurbs ||
                e == SurfaceKind.freeform ||
                e == SurfaceKind.patch,
          ),
          kind = analytical
              ? HybridRegionKind.analytical
              : hasFreeform && kinds.contains(SurfaceKind.patch)
              ? HybridRegionKind.freeformPatch
              : kinds.any(_analytical)
              ? HybridRegionKind.analyticalTransition
              : HybridRegionKind.mixed;
      result.add(
        HybridRegion(
          id: 'hybrid-region-${result.length + 1}',
          kind: kind,
          surfaceIds: group.map((e) => e.candidate.id).toList(),
          regionIds: group
              .expand((e) => e.candidate.regionIds)
              .toSet()
              .toList(),
          confidence:
              group
                  .map((e) => e.candidate.confidence)
                  .fold<double>(0, (a, b) => a + b) /
              group.length,
          explanation:
              'Grouped by shared regions, neighborhood and compatible analytical/freeform roles',
        ),
      );
    }
    return result;
  }

  bool _analytical(SurfaceKind kind) => {
    SurfaceKind.plane,
    SurfaceKind.cylinder,
    SurfaceKind.cone,
    SurfaceKind.sphere,
    SurfaceKind.torus,
    SurfaceKind.revolution,
    SurfaceKind.extrusion,
  }.contains(kind);
}
