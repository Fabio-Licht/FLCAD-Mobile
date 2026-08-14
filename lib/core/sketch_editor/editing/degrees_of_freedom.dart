import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_constraints/models/constraint_models.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../analytics/editor_analytics.dart';
import '../models/editor_models.dart';

class DegreesOfFreedomReader {
  const DegreesOfFreedomReader();
  DegreesOfFreedom read(
    SketchEngineApi sketch,
    ConstraintApi constraints,
    EditorAnalytics analytics,
  ) {
    final entityDof = sketch.engine.entities.length * 3;
    final effective = constraints.constraints
        .where(
          (c) =>
              c.enabled &&
              !c.suppressed &&
              c.status != ConstraintStatus.invalid,
        )
        .length;
    final remaining = (entityDof - effective).clamp(0, entityDof);
    final conflicts = constraints.constraints
        .where(
          (c) =>
              c.status == ConstraintStatus.conflicting ||
              c.status == ConstraintStatus.overdefined,
        )
        .length;
    analytics.dofSamples++;
    analytics.totalDof += remaining;
    return DegreesOfFreedom(
      remaining: remaining,
      translationX: remaining > 0,
      translationY: remaining > 1,
      rotation: remaining > 2,
      constraintStatus: conflicts > 0
          ? 'conflicting'
          : remaining == 0
          ? 'fully-defined'
          : 'underdefined',
      diagnostics: [if (conflicts > 0) '$conflicts conflicting constraints'],
    );
  }
}
