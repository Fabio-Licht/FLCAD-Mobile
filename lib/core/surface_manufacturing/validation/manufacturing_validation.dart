import '../constraints/manufacturing_constraint_solver.dart';
import '../models/surface_manufacturing_models.dart';

class ManufacturingValidator {
  const ManufacturingValidator(this.solver);
  final ManufacturingConstraintSolver solver;
  ManufacturingValidationResult validate(SurfaceManufacturingSession session) {
    final analysis = session.preview!.analysis,
        solution = solver.solve(session);
    final undercuts = analysis.undercutRisk < .8,
        intersection = analysis.twistRisk < .9;
    final draft =
        session.type == ManufacturingOperationType.draftAnalysis ||
        analysis.draftScore >= .2;
    final quality = analysis.quality >= .4;
    final errors = <String>[
      if (!undercuts) 'Critical undercut predicted',
      if (!intersection) 'Self-intersection predicted',
      if (!draft) 'Draft is impossible',
      if (!quality) 'Excessive quality degradation predicted',
      ...solution.conflicts,
    ];
    return ManufacturingValidationResult(
      valid: errors.isEmpty,
      undercuts: undercuts,
      selfIntersection: intersection,
      draft: draft,
      constraints: solution.valid,
      quality: quality,
      errors: List.unmodifiable(errors),
    );
  }
}
