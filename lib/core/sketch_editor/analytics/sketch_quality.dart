import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_constraints/diagnostics/constraint_diagnostics.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../models/editor_models.dart';

class SketchQualityCalculator {
  const SketchQualityCalculator();
  SketchQuality calculate(SketchEngineApi sketch, ConstraintApi constraints) {
    final diagnostics =
        constraints.engine.lastResult?.diagnostics ??
        const <ConstraintDiagnostic>[];
    final conflicts = diagnostics
        .where((d) => d.kind == ConstraintDiagnosticKind.conflict)
        .length;
    final over = diagnostics
        .where((d) => d.kind == ConstraintDiagnosticKind.overConstraint)
        .length;
    final under = diagnostics
        .where((d) => d.kind == ConstraintDiagnosticKind.underConstraint)
        .length;
    final redundant = diagnostics
        .where(
          (d) =>
              d.kind == ConstraintDiagnosticKind.redundant ||
              d.kind == ConstraintDiagnosticKind.duplicate,
        )
        .length;
    final broken = diagnostics
        .where(
          (d) =>
              d.kind == ConstraintDiagnosticKind.brokenReference ||
              d.kind == ConstraintDiagnosticKind.missingReference,
        )
        .length;
    final entities = sketch.engine.entities.values;
    final constructionRatio = entities.isEmpty
        ? 0.0
        : entities.where((e) => e.construction).length / entities.length;
    final complexity = (entities.length / 100).clamp(0, 1);
    final penalty =
        conflicts * 20 +
        over * 15 +
        under * 8 +
        redundant * 5 +
        broken * 15 +
        (constructionRatio > .5 ? 10 : 0) +
        (complexity * 10).round();
    final score = (100 - penalty).clamp(0, 100);
    final grade = score >= 90
        ? SketchQualityGrade.excellent
        : score >= 75
        ? SketchQualityGrade.good
        : score >= 50
        ? SketchQualityGrade.fair
        : SketchQualityGrade.poor;
    return SketchQuality(score, grade, {
      'conflicts': conflicts,
      'overdefined': over,
      'underdefined': under,
      'redundant': redundant,
      'constructionExcess': constructionRatio,
      'brokenReferences': broken,
      'complexity': complexity,
      'maintainability': score,
      'editability': score,
    });
  }
}
