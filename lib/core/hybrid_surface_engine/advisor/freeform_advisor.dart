import '../../adaptive_surface/models/surface_geometry.dart';
import '../models/hybrid_surface_models.dart';

class FreeformAdvice {
  const FreeformAdvice(
    this.recommendation,
    this.explanation,
    this.evidenceSurfaceIds,
    this.discarded,
  );
  final String recommendation, explanation;
  final List<String> evidenceSurfaceIds, discarded;
}

class FreeformAdvisor {
  const FreeformAdvisor();
  FreeformAdvice advise(HybridRegion region, List<SurfaceNetworkNode> nodes) {
    final relevant = nodes
            .where((e) => region.surfaceIds.contains(e.candidate.id))
            .toList(),
        analytical = relevant
            .where(
              (e) => {
                SurfaceKind.plane,
                SurfaceKind.cylinder,
                SurfaceKind.cone,
                SurfaceKind.sphere,
              }.contains(e.candidate.kind),
            )
            .toList(),
        lowCoverage = relevant.any((e) => e.candidate.coverage < .6);
    if (analytical.length == relevant.length) {
      return FreeformAdvice(
        'keep-analytical',
        'Analytical candidates provide robust coverage and editability.',
        region.surfaceIds,
        const ['single-nurbs'],
      );
    }
    if (lowCoverage) {
      return FreeformAdvice(
        'split-region',
        'Coverage is insufficient for one stable freeform representation.',
        region.surfaceIds,
        const ['single-nurbs'],
      );
    }
    if (relevant.any((e) => e.candidate.kind == SurfaceKind.patch)) {
      return FreeformAdvice(
        'use-patch',
        'Bounded irregular regions favor a local patch plan.',
        region.surfaceIds,
        const ['keep-analytical'],
      );
    }
    return FreeformAdvice(
      'consider-nurbs',
      'Variable curvature evidence may justify NURBS after kernel validation.',
      region.surfaceIds,
      const ['keep-analytical'],
    );
  }
}
