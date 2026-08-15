import '../constraints/fair_constraint_solver.dart';
import '../models/surface_fair_models.dart';

class FairValidator {
  const FairValidator(this.solver);
  final FairConstraintSolver solver;
  FairValidationResult validate(SurfaceFairSession session) {
    final prediction = session.prediction!;
    final solution = solver.solve(session.constraints, session.fixedRegions);
    final intersection = prediction.stress < .95;
    final continuity =
        session.transition != FairContinuity.g3 && prediction.curvature >= .35;
    final deformation = prediction.distortion < .8;
    final quality = prediction.quality >= .4;
    final errors = <String>[
      if (!intersection) 'Self-intersection predicted',
      if (!continuity) 'Continuity loss predicted',
      if (!deformation) 'Excessive deformation predicted',
      if (!quality) 'Quality degradation predicted',
      ...solution.conflicts,
    ];
    return FairValidationResult(
      valid: errors.isEmpty,
      selfIntersection: intersection,
      continuity: continuity,
      deformation: deformation,
      constraints: solution.valid,
      quality: quality,
      errors: List.unmodifiable(errors),
    );
  }
}
