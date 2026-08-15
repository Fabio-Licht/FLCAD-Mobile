import '../../surface_topology/models/surface_topology_models.dart';
import '../constraints/advanced_surface_constraint_solver.dart';
import '../models/advanced_surface_models.dart';

class AdvancedSurfaceValidator {
  const AdvancedSurfaceValidator(this.solver);
  final AdvancedSurfaceConstraintSolver solver;
  AdvancedSurfaceValidationResult validate(AdvancedSurfaceSession session) {
    final preview = session.preview!, solution = solver.solve(session);
    final topology = session.selectedPatches.every(
      (e) => e.health == TopologyHealth.healthy,
    );
    final intersection = preview.networkAnalysis.stress < .95;
    final quality = preview.predictedQuality >= .4;
    final continuity =
        session.continuity != AdvancedContinuity.g3 &&
        preview.predictedContinuity >= .35;
    final errors = <String>[
      if (!intersection) 'Self-intersection predicted',
      if (!topology) 'Topological inconsistency detected',
      if (!quality) 'Excessive quality degradation predicted',
      if (!continuity) 'Continuity loss predicted',
      ...solution.conflicts,
    ];
    return AdvancedSurfaceValidationResult(
      valid: errors.isEmpty,
      selfIntersection: intersection,
      topology: topology,
      quality: quality,
      continuity: continuity,
      constraints: solution.valid,
      errors: List.unmodifiable(errors),
    );
  }
}
