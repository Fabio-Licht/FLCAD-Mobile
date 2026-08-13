enum TopologyDefect {
  hole,
  selfIntersection,
  degeneratedFace,
  nonManifold,
  invalidNormal,
  duplicateVertex,
  noise,
}

class TopologyRepairPlan {
  const TopologyRepairPlan(this.defects, this.actions, this.confidence);
  final Set<TopologyDefect> defects;
  final List<String> actions;
  final double confidence;
}

class TopologyRepairEngine {
  const TopologyRepairEngine();
  TopologyRepairPlan plan(Set<TopologyDefect> defects) => TopologyRepairPlan(
    defects,
    defects
        .map(
          (d) => switch (d) {
            TopologyDefect.hole => 'auto-bridge',
            TopologyDefect.selfIntersection => 'local-remesh',
            TopologyDefect.degeneratedFace => 'remove-degenerate',
            TopologyDefect.nonManifold => 'split-non-manifold',
            TopologyDefect.invalidNormal => 'repair-normal',
            TopologyDefect.duplicateVertex => 'adaptive-weld',
            TopologyDefect.noise => 'constrained-smooth',
          },
        )
        .toList(),
    defects.isEmpty ? 1 : .75,
  );
}
