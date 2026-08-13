import '../models/decision_models.dart';

abstract interface class DecisionRepository {
  Future<void> save(EngineeringDecision decision);
  Future<EngineeringDecision?> findById(String projectId, String id);
  Future<List<EngineeringDecision>> findAll(String projectId);
}

class InMemoryDecisionRepository implements DecisionRepository {
  final Map<String, Map<String, EngineeringDecision>> _values = {};
  @override
  Future<void> save(EngineeringDecision decision) async =>
      _values.putIfAbsent(decision.projectId, () => {})[decision.id] = decision;
  @override
  Future<EngineeringDecision?> findById(String projectId, String id) async =>
      _values[projectId]?[id];
  @override
  Future<List<EngineeringDecision>> findAll(String projectId) async =>
      List.unmodifiable(_values[projectId]?.values ?? const []);
}
