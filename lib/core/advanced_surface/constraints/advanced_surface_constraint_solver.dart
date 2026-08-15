import '../../surface_boundary/constraints/boundary_constraint_solver.dart';
import '../models/advanced_surface_models.dart';

class AdvancedSurfaceConstraintSolver {
  const AdvancedSurfaceConstraintSolver(this.boundarySolver);
  final BoundaryConstraintSolver boundarySolver;
  BoundaryConstraintSolution solve(AdvancedSurfaceSession session) =>
      boundarySolver.solve(session.constraints, session.fixedRegions, '');
}
