import 'dart:isolate';
import '../entities/sketch_entity.dart';
import '../constraints/sketch_constraint.dart';
import '../solver/adaptive_constraint_solver.dart';

abstract interface class SketchComputeRuntime {
  Future<SketchSolveResult> solve(
    List<SketchEntity> entities,
    List<SketchConstraint> constraints,
  );
}

class IsolateSketchRuntime {
  const IsolateSketchRuntime();
  Future<SketchSolveResult> solve(
    List<SketchEntity> entities,
    List<SketchConstraint> constraints,
  ) => Isolate.run(
    () => AdaptiveConstraintSolver().solve(entities, constraints),
  );
}

abstract interface class GPUSketchRenderer {
  Future<void> update(String sketchId, List<SketchEntity> changedEntities);
}
