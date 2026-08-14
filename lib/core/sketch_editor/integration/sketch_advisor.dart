import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../analytics/sketch_quality.dart';
import '../models/editor_models.dart';

class SketchAdvisor {
  const SketchAdvisor();
  List<SketchRecommendation> analyze(
    SketchEngineApi sketch,
    ConstraintApi constraints,
    DegreesOfFreedom dof,
  ) {
    final quality = const SketchQualityCalculator().calculate(
      sketch,
      constraints,
    );
    final result = <SketchRecommendation>[];
    if (dof.remaining > 0) {
      result.add(
        _recommend(
          AdvisorKind.dof,
          'Reduce remaining degrees of freedom',
          '$dof.remaining degrees of freedom remain',
          'The sketch is not fully defined',
          92,
          'More predictable edits',
          'Add driving dimensions or fixed constraints',
          'The recommendation is advisory and does not mutate constraints.',
        ),
      );
    }
    if (quality.score < 75) {
      result.add(
        _recommend(
          AdvisorKind.quality,
          'Improve sketch quality',
          'Current quality is ${quality.grade.name}',
          'Diagnostics reduce maintainability',
          85,
          'A simpler and more editable sketch',
          'Review conflicts and broken references',
          'Quality combines solver diagnostics and parametric complexity.',
        ),
      );
    }
    if (sketch.engine.entities.values.where((e) => e.construction).length >
        sketch.engine.entities.length / 2) {
      result.add(
        _recommend(
          AdvisorKind.construction,
          'Review construction geometry',
          'Construction geometry dominates the sketch',
          'Excess helpers increase visual complexity',
          78,
          'Cleaner editing',
          'Remove unused construction entities',
          'No entity is deleted automatically.',
        ),
      );
    }
    return result;
  }

  SketchRecommendation _recommend(
    AdvisorKind kind,
    String title,
    String description,
    String reason,
    int confidence,
    String impact,
    String action,
    String explanation,
  ) => SketchRecommendation(
    kind: kind,
    title: title,
    description: description,
    reason: reason,
    confidence: confidence,
    expectedImpact: impact,
    suggestedAction: action,
    technicalExplanation: explanation,
  );
}
