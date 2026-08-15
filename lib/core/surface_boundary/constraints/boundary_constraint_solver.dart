import '../../surface_operations/models/surface_operation_models.dart';
import '../models/surface_boundary_models.dart';

class BoundaryConstraintSolution {
  const BoundaryConstraintSolution(this.valid, this.conflicts);
  final bool valid;
  final List<String> conflicts;
}

class BoundaryConstraintSolver {
  const BoundaryConstraintSolver();
  BoundaryConstraintSolution solve(
    List<SurfaceConstraint> constraints,
    List<BoundaryFixedRegion> fixedRegions,
    String editedBoundaryId,
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
    final ids = <String>{};
    for (final region in fixedRegions) {
      if (!ids.add(region.id)) {
        conflicts.add('Duplicate fixed region: ${region.id}');
      }
      if (region.type == BoundaryFixedRegionType.boundary &&
          region.targetId == editedBoundaryId) {
        conflicts.add('Edited boundary is fixed: $editedBoundaryId');
      }
    }
    return BoundaryConstraintSolution(
      conflicts.isEmpty,
      List.unmodifiable(conflicts),
    );
  }
}
