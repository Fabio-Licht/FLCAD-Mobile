enum SurfaceContinuityLevel {
  g0,
  g1,
  g2,
  g3,
  g4,
  curvatureFlow,
  energyMinimized,
}

class SurfaceContinuityConstraint {
  const SurfaceContinuityConstraint({
    required this.id,
    required this.surfaceIds,
    required this.level,
    this.weight = 1,
  });
  final String id;
  final List<String> surfaceIds;
  final SurfaceContinuityLevel level;
  final double weight;
  Map<String, dynamic> toJson() => {
    'id': id,
    'surfaceIds': surfaceIds,
    'level': level.name,
    'weight': weight,
  };
  factory SurfaceContinuityConstraint.fromJson(Map<String, dynamic> j) =>
      SurfaceContinuityConstraint(
        id: j['id'] as String,
        surfaceIds: (j['surfaceIds'] as List).cast(),
        level: SurfaceContinuityLevel.values.byName(j['level'] as String),
        weight: (j['weight'] as num? ?? 1).toDouble(),
      );
}

class ContinuityEvaluation {
  const ContinuityEvaluation(this.level, this.error, this.satisfied);
  final SurfaceContinuityLevel level;
  final double error;
  final bool satisfied;
}

class SurfaceContinuityEngine {
  const SurfaceContinuityEngine({this.tolerance = 1e-4});
  final double tolerance;
  ContinuityEvaluation evaluate(
    SurfaceContinuityConstraint c,
    double boundaryPositionError,
    double tangentError,
    double curvatureError,
  ) {
    final error = switch (c.level) {
      SurfaceContinuityLevel.g0 => boundaryPositionError,
      SurfaceContinuityLevel.g1 => boundaryPositionError + tangentError,
      SurfaceContinuityLevel.g2 ||
      SurfaceContinuityLevel.g3 ||
      SurfaceContinuityLevel.g4 ||
      SurfaceContinuityLevel.curvatureFlow ||
      SurfaceContinuityLevel.energyMinimized =>
        boundaryPositionError + tangentError + curvatureError,
    };
    return ContinuityEvaluation(c.level, error, error <= tolerance);
  }
}
