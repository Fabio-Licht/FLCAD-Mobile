import '../builders/surface_builder.dart';

class SolverWeights {
  const SolverWeights({
    this.accuracy = .45,
    this.continuity = .25,
    this.stability = .15,
    this.simplicity = .15,
  });
  final double accuracy, continuity, stability, simplicity;
}

class SurfaceSolverResult {
  const SurfaceSolverResult(this.best, this.candidates, this.scores);
  final SurfaceCandidate best;
  final List<SurfaceCandidate> candidates;
  final Map<String, double> scores;
}

class AdaptiveSurfaceSolver {
  AdaptiveSurfaceSolver(Iterable<SurfaceBuilder> builders)
    : _builders = List.unmodifiable(builders);
  final List<SurfaceBuilder> _builders;
  Future<SurfaceSolverResult> solve(
    SurfaceBuildRequest request, {
    SolverWeights weights = const SolverWeights(),
  }) async {
    final eligible = _builders
        .where(
          (b) =>
              request.targetKind == null ||
              b.supportedKinds.contains(request.targetKind),
        )
        .toList();
    if (eligible.isEmpty) {
      throw StateError('No solver supports ${request.targetKind}');
    }
    final attempts = await Future.wait(
          eligible.map((b) async {
            try {
              return await b.build(request);
            } on ArgumentError {
              return null;
            }
          }),
        ),
        candidates = attempts.whereType<SurfaceCandidate>().toList();
    if (candidates.isEmpty) {
      throw StateError('All eligible surface solvers failed');
    }
    final scores = <String, double>{};
    for (final c in candidates) {
      scores[c.solverId] =
          (1 / (1 + c.metrics.rmsError)) * weights.accuracy +
          c.metrics.continuity * weights.continuity +
          c.metrics.confidence * weights.stability +
          (1 - c.complexity.clamp(0, 1)) * weights.simplicity;
    }
    candidates.sort(
      (a, b) => scores[b.solverId]!.compareTo(scores[a.solverId]!),
    );
    return SurfaceSolverResult(candidates.first, candidates, scores);
  }
}
