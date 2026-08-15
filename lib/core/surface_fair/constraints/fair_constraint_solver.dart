import '../../surface_operations/models/surface_operation_models.dart';
import '../models/surface_fair_models.dart';

class FairConstraintSolution {
  const FairConstraintSolution(this.valid, this.conflicts);
  final bool valid;
  final List<String> conflicts;
}

class FairConstraintSolver {
  const FairConstraintSolver();
  FairConstraintSolution solve(
    List<SurfaceConstraint> constraints,
    List<FairFixedRegion> fixedRegions,
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
      if (region.type == FairFixedRegionType.radius &&
          (region.radius == null || region.radius! <= 0)) {
        conflicts.add('Invalid fixed radius: ${region.id}');
      }
    }
    return FairConstraintSolution(
      conflicts.isEmpty,
      List.unmodifiable(conflicts),
    );
  }
}
