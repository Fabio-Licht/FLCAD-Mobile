import '../../smart_regions/models/geometry.dart';
import '../constraints/topology_constraint.dart';

enum MorphOperation {
  push,
  pull,
  inflate,
  deflate,
  relax,
  smooth,
  flatten,
  adaptiveOffset,
  compensation,
  spring,
  bending,
  shrink,
  expand,
  twist,
  localScale,
  thickness,
  curvatureFlow,
}

class MorphRequest {
  const MorphRequest({
    required this.operation,
    required this.vertexIndices,
    required this.amount,
    this.direction,
    this.weights = const {},
    this.parameters = const {},
  });
  final MorphOperation operation;
  final Set<int> vertexIndices;
  final double amount;
  final Vec3? direction;
  final Map<int, double> weights;
  final Map<String, double> parameters;
}

class MorphResult {
  const MorphResult(this.displacements, this.warnings);
  final Map<int, Vec3> displacements;
  final List<String> warnings;
}

class MeshMorphEngine {
  const MeshMorphEngine();
  MorphResult apply(
    MeshTopology mesh,
    MorphRequest request,
    List<TopologyConstraint> constraints,
  ) {
    final output = <int, Vec3>{}, warnings = <String>[];
    for (final index in request.vertexIndices) {
      if (index < 0 || index >= mesh.vertices.length) continue;
      if (_has(constraints, TopologyConstraintType.frozen, index)) continue;
      final normal = _vertexNormal(mesh, index),
          direction = (request.direction ?? normal).normalized,
          weight = request.weights[index] ?? 1;
      var amount = request.amount * weight;
      if (request.operation == MorphOperation.pull ||
          request.operation == MorphOperation.deflate ||
          request.operation == MorphOperation.shrink) {
        amount = -amount;
      }
      final limit = _limit(constraints, index);
      if (limit != null && amount.abs() > limit) {
        amount = amount.sign * limit;
        warnings.add('Vertex $index clamped to $limit');
      }
      var displacement = Vec3(
        direction.x * amount,
        direction.y * amount,
        direction.z * amount,
      );
      if (request.operation == MorphOperation.flatten) {
        final axis = request.direction ?? const Vec3(0, 0, 1);
        displacement = Vec3(axis.x * amount, axis.y * amount, axis.z * amount);
      }
      output[index] = displacement;
    }
    return MorphResult(output, warnings);
  }

  bool _has(List<TopologyConstraint> c, TopologyConstraintType type, int i) =>
      c.any((v) => v.enabled && v.type == type && v.vertexIndices.contains(i));
  double? _limit(List<TopologyConstraint> c, int i) {
    final values = c
        .where(
          (v) =>
              v.enabled &&
              v.type == TopologyConstraintType.maxDisplacement &&
              v.vertexIndices.contains(i),
        )
        .map((v) => v.parameters['maximum'])
        .whereType<double>()
        .toList();
    return values.isEmpty ? null : values.reduce((a, b) => a < b ? a : b);
  }

  Vec3 _vertexNormal(MeshTopology mesh, int index) {
    final triangles = <int>[];
    for (var i = 0; i < mesh.triangles.length; i++) {
      final t = mesh.triangles[i];
      if (t.a == index || t.b == index || t.c == index) triangles.add(i);
    }
    return triangles.isEmpty
        ? const Vec3(0, 0, 1)
        : triangles
              .map(mesh.triangleNormal)
              .fold<Vec3>(const Vec3(0, 0, 0), (a, b) => a + b)
              .normalized;
  }
}
