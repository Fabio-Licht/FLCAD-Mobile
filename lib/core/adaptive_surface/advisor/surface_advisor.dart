import '../builders/surface_builder.dart';
import '../models/surface_geometry.dart';

class SurfaceAdvice {
  const SurfaceAdvice(
    this.kind,
    this.degreeU,
    this.degreeV,
    this.predictedError,
    this.continuity,
    this.confidence,
  );
  final SurfaceKind kind;
  final int degreeU, degreeV;
  final double predictedError, confidence;
  final String continuity;
}

abstract interface class SurfaceAdvisor {
  Future<List<SurfaceAdvice>> advise(SurfaceBuildRequest request);
}

class RuleBasedSurfaceAdvisor implements SurfaceAdvisor {
  const RuleBasedSurfaceAdvisor();
  @override
  Future<List<SurfaceAdvice>> advise(SurfaceBuildRequest r) async {
    final size = r.samples.length,
        degree = size > 100 ? 5 : 3,
        grid = mathGrid(size);
    return [
      SurfaceAdvice(
        r.targetKind ?? SurfaceKind.nurbs,
        grid < degree ? grid : degree,
        grid < degree ? grid : degree,
        size == 0 ? double.infinity : 1 / size,
        'G2',
        (size / 100).clamp(.2, .9),
      ),
    ];
  }

  int mathGrid(int value) {
    var result = 1;
    while (result * result < value) {
      result++;
    }
    return result;
  }
}

class RegionSplittingAdvice {
  const RegionSplittingAdvice(this.shouldSplit, this.reason, this.confidence);
  final bool shouldSplit;
  final String reason;
  final double confidence;
}

class RegionSplittingAdvisor {
  const RegionSplittingAdvisor();
  RegionSplittingAdvice evaluate(
    double curvatureVariance,
    int disconnectedComponents,
  ) => RegionSplittingAdvice(
    curvatureVariance > .25 || disconnectedComponents > 1,
    curvatureVariance > .25
        ? 'Multiple curvature regimes'
        : 'Disconnected region',
    ((curvatureVariance + disconnectedComponents / 3) / 2).clamp(0, 1),
  );
}
