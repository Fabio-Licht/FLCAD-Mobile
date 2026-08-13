import '../models/reconstruction_models.dart';

class ReconstructionDependencyGraph {
  ReconstructionDependencyGraph(Iterable<ReconstructionStage> stages)
    : _stages = {for (final s in stages) s.id: s} {
    for (final stage in _stages.values) {
      for (final dependency in stage.dependencies) {
        if (!_stages.containsKey(dependency)) {
          throw StateError('Missing dependency $dependency for ${stage.id}');
        }
      }
    }
    if (hasCycle) throw StateError('Reconstruction dependency cycle detected');
  }
  final Map<String, ReconstructionStage> _stages;
  Iterable<ReconstructionStage> get stages => _stages.values;
  Set<String> dependenciesOf(String id) =>
      Set.unmodifiable(_stages[id]?.dependencies ?? const []);
  Set<String> dependentsOf(String id) => _stages.values
      .where((s) => s.dependencies.contains(id))
      .map((s) => s.id)
      .toSet();
  bool get hasCycle {
    final visiting = <String>{}, visited = <String>{};
    bool visit(String id) {
      if (visiting.contains(id)) return true;
      if (visited.contains(id)) return false;
      visiting.add(id);
      for (final d in _stages[id]!.dependencies) {
        if (visit(d)) return true;
      }
      visiting.remove(id);
      visited.add(id);
      return false;
    }

    return _stages.keys.any(visit);
  }

  List<String> topologicalOrder() {
    final indegree = {for (final id in _stages.keys) id: 0};
    for (final stage in _stages.values) {
      indegree[stage.id] = stage.dependencies.length;
    }
    final ready = indegree.entries
            .where((e) => e.value == 0)
            .map((e) => e.key)
            .toList(),
        result = <String>[];
    while (ready.isNotEmpty) {
      ready.sort((a, b) => _stages[a]!.order.compareTo(_stages[b]!.order));
      final id = ready.removeAt(0);
      result.add(id);
      for (final dependent in dependentsOf(id)) {
        indegree[dependent] = indegree[dependent]! - 1;
        if (indegree[dependent] == 0) ready.add(dependent);
      }
    }
    if (result.length != _stages.length) {
      throw StateError('Dependency graph is not acyclic');
    }
    return result;
  }

  bool dependenciesCompleted(
    String id,
    Map<String, ReconstructionStageStatus> states,
  ) => dependenciesOf(
    id,
  ).every((d) => states[d] == ReconstructionStageStatus.completed);
}
