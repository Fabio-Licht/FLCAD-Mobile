import '../models/decision_models.dart';

class GoalEngine {
  final Map<String, EngineeringGoal> _goals = {};
  void add(EngineeringGoal goal) => _goals[goal.id] = goal;
  EngineeringGoal? find(String id) => _goals[id];
  List<EngineeringGoal> children(String id) => _goals.values
      .where((goal) => goal.parentId == id)
      .toList(growable: false);
  bool canComplete(String id) {
    final goal = _goals[id] ?? (throw StateError('Goal $id not found'));
    return goal.prerequisiteIds.every(
      (required) => _goals[required]?.completed == true,
    );
  }

  void complete(String id, Iterable<String> satisfiedCriteria) {
    final goal = _goals[id] ?? (throw StateError('Goal $id not found'));
    if (!canComplete(id) ||
        !goal.completionCriteria.every(satisfiedCriteria.contains)) {
      throw StateError('Goal $id prerequisites or criteria are incomplete');
    }
    _goals[id] = EngineeringGoal(
      id: goal.id,
      projectId: goal.projectId,
      title: goal.title,
      parentId: goal.parentId,
      prerequisiteIds: goal.prerequisiteIds,
      completionCriteria: goal.completionCriteria,
      completed: true,
    );
  }

  List<EngineeringGoal> get values => List.unmodifiable(_goals.values);
}
