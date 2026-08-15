import '../../surface_operations/models/surface_operation_models.dart';
import '../models/surface_reduce_models.dart';

class ReduceConstraintSolution {
  const ReduceConstraintSolution(this.valid, this.conflicts);
  final bool valid;
  final List<String> conflicts;
}

class ReduceConstraintSolver {
  const ReduceConstraintSolver();
  ReduceConstraintSolution solve(
    List<SurfaceConstraint> constraints,
    List<FixedRegion> fixedRegions,
  ) {
    final conflicts = <String>[];
    final targets = <String, SurfaceConstraintType>{};
    for (final constraint in constraints.where((e) => e.enabled)) {
      final previous = targets[constraint.targetId];
      if (previous != null && previous != constraint.type) {
        conflicts.add('Conflicting constraints on ${constraint.targetId}');
      }
      targets[constraint.targetId] = constraint.type;
    }
    final fixedIds = <String>{};
    for (final region in fixedRegions) {
      if (!fixedIds.add(region.id)) {
        conflicts.add('Duplicate fixed region: ${region.id}');
      }
      if (region.type == FixedRegionType.distance &&
          (region.distance == null || region.distance! < 0)) {
        conflicts.add('Invalid fixed distance: ${region.id}');
      }
    }
    return ReduceConstraintSolution(
      conflicts.isEmpty,
      List.unmodifiable(conflicts),
    );
  }
}
