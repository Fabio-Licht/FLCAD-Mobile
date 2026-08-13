import '../../smart_regions/models/geometry.dart';
import '../constraints/topology_constraint.dart';
import '../morphing/mesh_morph_engine.dart';

class CompensationIntent {
  const CompensationIntent({
    required this.amount,
    required this.process,
    this.pressureMap = const {},
    this.thicknessMap = const {},
    this.direction,
  });
  final double amount;
  final String process;
  final Map<int, double> pressureMap, thicknessMap;
  final Vec3? direction;
}

class AdaptiveCompensationEngine {
  const AdaptiveCompensationEngine();
  MorphRequest plan(
    Set<int> vertices,
    CompensationIntent intent,
    List<TopologyConstraint> constraints,
  ) {
    final weights = <int, double>{};
    for (final index in vertices) {
      final pressure = intent.pressureMap[index] ?? 1,
          thickness = intent.thicknessMap[index] ?? 1;
      weights[index] = (pressure / thickness).clamp(0, 2).toDouble();
    }
    return MorphRequest(
      operation: MorphOperation.compensation,
      vertexIndices: vertices,
      amount: intent.amount,
      direction: intent.direction,
      weights: weights,
      parameters: {'manufacturingProcess': intent.process.hashCode.toDouble()},
    );
  }
}
