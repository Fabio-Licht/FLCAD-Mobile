import '../engine/engineering_decision_engine.dart';
import '../models/decision_models.dart';

class DecisionApi {
  DecisionApi({EngineeringDecisionEngine? engine})
    : engine = engine ?? EngineeringDecisionEngine();
  final EngineeringDecisionEngine engine;
  Future<EngineeringDecision> create(DecisionRequest request) =>
      engine.decide(request);
  Future<List<EngineeringDecision>> list(String projectId) =>
      engine.repository.findAll(projectId);
  EngineeringDecision explain(String id) =>
      engine.graph.find(id) ?? (throw StateError('Decision $id not found'));
  DecisionSimulationResult simulate(String id, String alternativeId) =>
      engine.simulate(id, alternativeId);
}
