import '../../surface_topology/models/surface_topology_models.dart';
import '../constraints/boundary_constraint_solver.dart';
import '../models/surface_boundary_models.dart';

class BoundaryValidator {
  const BoundaryValidator(this.solver);
  final BoundaryConstraintSolver solver;
  BoundaryValidationResult validate(SurfaceBoundarySession session) {
    final preview = session.preview!, analysis = preview.analysis;
    final solution = solver.solve(
      session.constraints,
      session.fixedRegions,
      session.boundary.id,
    );
    final boundary =
        session.boundary.health == TopologyHealth.healthy &&
        session.boundary.length > 0;
    final intersection = analysis.stress < .95;
    final continuity =
        session.continuity != BoundaryContinuity.g3 && analysis.quality >= .4;
    final quality = analysis.quality >= .4;
    final errors = <String>[
      if (!intersection) 'Self-intersection predicted',
      if (!boundary) 'Invalid boundary',
      if (!continuity) 'Continuity loss predicted',
      if (!quality) 'Excessive quality degradation predicted',
      ...solution.conflicts,
    ];
    return BoundaryValidationResult(
      valid: errors.isEmpty,
      selfIntersection: intersection,
      boundary: boundary,
      continuity: continuity,
      constraints: solution.valid,
      quality: quality,
      errors: List.unmodifiable(errors),
    );
  }
}
