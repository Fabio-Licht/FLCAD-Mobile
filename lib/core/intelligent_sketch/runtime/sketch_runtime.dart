import '../../engineering/runtime/engineering_runtime.dart';
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
  ) => EngineeringRuntime.shared
      .submit(
        'sketch:${DateTime.now().microsecondsSinceEpoch}',
        () => AdaptiveConstraintSolver().solve(entities, constraints),
        namespace: 'sketch',
      )
      .future;
}

abstract interface class GPUSketchRenderer {
  Future<void> update(String sketchId, List<SketchEntity> changedEntities);
}
