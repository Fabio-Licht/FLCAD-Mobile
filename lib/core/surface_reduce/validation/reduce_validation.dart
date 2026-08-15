import '../../surface_continuity/models/surface_continuity_models.dart';
import '../../surface_topology/models/surface_topology_models.dart';
import '../constraints/reduce_constraint_solver.dart';
import '../models/surface_reduce_models.dart';

class ReduceValidator {
  const ReduceValidator(this.solver);
  final ReduceConstraintSolver solver;
  ReduceValidationResult validate(
    SurfaceReduceSession session,
    SurfaceTopologyReport topology,
    SurfaceQualityReport quality,
  ) {
    final prediction = session.prediction!;
    final solution = solver.solve(session.constraints, session.fixedRegions);
    final patch = session.patch.health == TopologyHealth.healthy;
    final boundary =
        session.patch.boundaryIds.isNotEmpty &&
        session.patch.boundaryIds.every(
          (id) => topology.boundaries.any(
            (b) => b.id == id && b.health == TopologyHealth.healthy,
          ),
        );
    final intersection = prediction.distortion < .95 && prediction.stress < .95;
    final continuity =
        session.transition != ReduceContinuity.g3 && prediction.quality >= .4;
    final errors = <String>[
      if (!intersection) 'Self-intersection predicted',
      if (!patch) 'Invalid patch',
      if (!boundary) 'Invalid boundary',
      if (!continuity) 'Continuity impossible',
      ...solution.conflicts,
    ];
    return ReduceValidationResult(
      valid: errors.isEmpty,
      selfIntersection: intersection,
      patch: patch,
      boundary: boundary,
      continuity: continuity,
      constraints: solution.valid,
      errors: List.unmodifiable(errors),
    );
  }
}
