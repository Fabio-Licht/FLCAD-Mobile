import '../parametric_solver/parametric_solver.dart';

/// The only gateway through which a Feature definition may request a
/// geometric update. Domain adapters build the abstract request and apply the
/// returned propagation plan inside their own atomic transaction.
class FeatureUpdateSolver {
  const FeatureUpdateSolver({
    this.solver = const ParametricPropagationSolver(),
  });

  final ParametricPropagationSolver solver;

  T update<T>({
    required ParametricSolveRequest request,
    required T Function(ParametricMotionPlan plan) apply,
  }) {
    final plan = solver.solve(request);
    return apply(plan);
  }
}
