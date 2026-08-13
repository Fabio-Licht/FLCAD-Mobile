import '../../smart_regions/models/geometry.dart';
import '../classification/classification_engine.dart';
import '../hypothesis/hypothesis_engine.dart';
import '../manufacturing/manufacturing_engine.dart';
import '../models/intelligence_models.dart';
import '../observation/observation_engine.dart';
import '../planning/reconstruction_planner.dart';
import '../reasoning/explanation_engine.dart';
import '../strategies/strategy_engine.dart';
import '../validation/intelligence_validator.dart';

class ReverseBrainResult {
  const ReverseBrainResult(this.twin, this.explanation);
  final ReasoningSnapshot twin;
  final String explanation;
}

class ReverseBrain {
  const ReverseBrain({
    this.observer = const ObservationEngine(),
    this.classifier = const GeometryClassificationEngine(),
    this.manufacturing = const ManufacturingIntelligence(),
    this.hypotheses = const HypothesisEngine(),
    this.planner = const ReverseEngineeringPlanner(),
    this.strategies = const StrategyEngine(),
    this.validator = const IntelligenceValidator(),
    this.explainer = const ExplanationEngine(),
  });
  final ObservationEngine observer;
  final GeometryClassificationEngine classifier;
  final ManufacturingIntelligence manufacturing;
  final HypothesisEngine hypotheses;
  final ReverseEngineeringPlanner planner;
  final StrategyEngine strategies;
  final IntelligenceValidator validator;
  final ExplanationEngine explainer;
  ReverseBrainResult reason(String projectId, MeshTopology mesh) {
    final observation = observer.observe(mesh),
        classes = classifier.classify(observation),
        processes = manufacturing.estimate(observation, classes),
        generated = hypotheses.generate(observation, classes),
        plan = planner.plan(mesh.id, classes, generated),
        candidates = strategies.generate(plan, classes, processes),
        decision = strategies.select(candidates),
        validation = validator.validate(observation, decision),
        snapshot = ReasoningSnapshot(
          projectId: projectId,
          meshId: mesh.id,
          observation: observation,
          classifications: classes,
          manufacturing: processes,
          hypotheses: generated,
          plan: plan,
          decision: decision,
          validation: validation,
          createdAt: DateTime.now().toUtc(),
        );
    return ReverseBrainResult(
      snapshot,
      explainer.explain(decision, validation),
    );
  }
}
