import '../models/surface_operation_models.dart';

class SurfaceConstraintSolution {
  const SurfaceConstraintSolution(this.satisfied, this.conflicts);
  final bool satisfied;
  final List<String> conflicts;
}

class SurfaceConstraintSolver {
  const SurfaceConstraintSolver();
  SurfaceConstraintSolution solve(SurfaceOperation operation) {
    final conflicts = <String>[];
    final active = operation.constraints.where((e) => e.enabled);
    for (final constraint in active) {
      if (constraint.targetId.isEmpty) {
        conflicts.add('Constraint ${constraint.id} has no target');
      }
      if ((constraint.type == SurfaceConstraintType.lockedBoundary ||
              constraint.type == SurfaceConstraintType.anchor) &&
          operation.preview?.affectedBoundaries.contains(constraint.targetId) ==
              true) {
        conflicts.add(
          'Boundary ${constraint.targetId} is locked by ${constraint.type.name}',
        );
      }
    }
    final fixed = active
        .where((e) => e.type == SurfaceConstraintType.fixedPoint)
        .map((e) => e.targetId)
        .toSet();
    final moving = operation.parameters['fixedPoint'] as String?;
    if (moving != null && fixed.contains(moving)) {
      conflicts.add('Fixed point $moving cannot be moved');
    }
    return SurfaceConstraintSolution(
      conflicts.isEmpty,
      List.unmodifiable(conflicts),
    );
  }
}
