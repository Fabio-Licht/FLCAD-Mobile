import '../models/reconstruction_intelligence_models.dart';

class ERIReconstructionGraph {
  ERIReconstructionGraph(Iterable<ERIPlanNode> nodes)
    : _nodes = {for (final n in nodes) n.id: n} {
    for (final node in _nodes.values) {
      for (final dependency in node.dependencies) {
        if (!_nodes.containsKey(dependency)) {
          throw StateError('Missing dependency $dependency for ${node.id}');
        }
      }
    }
    if (hasCycle) throw StateError('ERI reconstruction graph contains a cycle');
  }
  final Map<String, ERIPlanNode> _nodes;
  bool get hasCycle {
    final visiting = <String>{}, visited = <String>{};
    bool visit(String id) {
      if (visiting.contains(id)) return true;
      if (visited.contains(id)) return false;
      visiting.add(id);
      for (final d in _nodes[id]!.dependencies) {
        if (visit(d)) return true;
      }
      visiting.remove(id);
      visited.add(id);
      return false;
    }

    return _nodes.keys.any(visit);
  }

  Set<String> dependents(String id) {
    final result = <String>{}, queue = [id];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final n in _nodes.values.where(
        (n) => n.dependencies.contains(current),
      )) {
        if (result.add(n.id)) queue.add(n.id);
      }
    }
    return result;
  }

  List<ERIPlanNode> ordered() {
    final indegree = {
          for (final n in _nodes.values) n.id: n.dependencies.length,
        },
        ready = indegree.entries
            .where((e) => e.value == 0)
            .map((e) => e.key)
            .toList(),
        result = <ERIPlanNode>[];
    while (ready.isNotEmpty) {
      ready.sort((a, b) => _nodes[b]!.priority.compareTo(_nodes[a]!.priority));
      final id = ready.removeAt(0);
      result.add(_nodes[id]!);
      for (final d in _nodes.values.where((n) => n.dependencies.contains(id))) {
        indegree[d.id] = indegree[d.id]! - 1;
        if (indegree[d.id] == 0) ready.add(d.id);
      }
    }
    if (result.length != _nodes.length) {
      throw StateError('Cannot order cyclic graph');
    }
    return result;
  }

  List<ERIPlanNode> removeRedundant() {
    final seen = <String>{};
    return ordered()
        .where(
          (n) => seen.add(
            '${n.type.name}:${n.sourceIds.join(',')}:${n.dependencies.join(',')}',
          ),
        )
        .toList();
  }
}
