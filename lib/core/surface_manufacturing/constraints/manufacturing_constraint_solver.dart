import '../../surface_boundary/constraints/boundary_constraint_solver.dart';
import '../models/surface_manufacturing_models.dart';

class ManufacturingConstraintSolver {
  const ManufacturingConstraintSolver(this.boundarySolver);
  final BoundaryConstraintSolver boundarySolver;
  BoundaryConstraintSolution solve(SurfaceManufacturingSession session) =>
      boundarySolver.solve(session.constraints, session.fixedRegions, '');
}
