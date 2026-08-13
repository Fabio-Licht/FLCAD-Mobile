import '../constraints/sketch_constraint.dart';
import '../engine/sketch_engine.dart';
import '../entities/sketch_entity.dart';
import '../models/sketch.dart';

sealed class SketchPipelineStep {
  const SketchPipelineStep();
}

class AddEntityStep extends SketchPipelineStep {
  const AddEntityStep(this.entity);
  final SketchEntity entity;
}

class AddConstraintStep extends SketchPipelineStep {
  const AddConstraintStep(this.constraint);
  final SketchConstraint constraint;
}

class SolveSketchStep extends SketchPipelineStep {
  const SolveSketchStep();
}

class SketchPipeline {
  const SketchPipeline(this.engine);
  final SketchEngine engine;
  Future<IntelligentSketch> execute(
    IntelligentSketch sketch,
    List<SketchPipelineStep> steps,
  ) async {
    var current = sketch;
    for (final step in steps) {
      switch (step) {
        case AddEntityStep s:
          current = await engine.update(
            current,
            entities: [...current.entities, s.entity],
          );
        case AddConstraintStep s:
          current = await engine.update(
            current,
            constraints: [...current.constraints, s.constraint],
          );
        case SolveSketchStep _:
          current = await engine.solve(current);
      }
    }
    return current;
  }
}
