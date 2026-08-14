class ConstraintGraph {
  final Set<String> _nodes = {};
  final Map<String, Set<String>> _edges = {};
  Set<String> get nodes => Set.unmodifiable(_nodes);
  Map<String, Set<String>> get edges =>
      Map.unmodifiable(_edges.map((k, v) => MapEntry(k, Set.unmodifiable(v))));
  void addNode(String id) {
    _nodes.add(id);
    _edges.putIfAbsent(id, () => {});
  }

  void removeNode(String id) {
    _nodes.remove(id);
    _edges.remove(id);
    for (final values in _edges.values) {
      values.remove(id);
    }
  }

  void connect(String dependency, String dependent) {
    if (!_nodes.contains(dependency) || !_nodes.contains(dependent)) {
      throw StateError('Unknown constraint graph node');
    }
    if (dependency == dependent || _reaches(dependent, dependency)) {
      throw StateError(
        'Circular constraint dependency: $dependency -> $dependent',
      );
    }
    _edges[dependency]!.add(dependent);
  }

  Set<String> downstream(String id) {
    final result = <String>{};
    void visit(String node) {
      for (final next in _edges[node] ?? const <String>{}) {
        if (result.add(next)) visit(next);
      }
    }

    visit(id);
    return result;
  }

  bool _reaches(String from, String target, [Set<String>? visited]) {
    if (from == target) return true;
    final seen = visited ?? <String>{};
    if (!seen.add(from)) return false;
    return _edges[from]?.any((n) => _reaches(n, target, seen)) ?? false;
  }

  Map<String, dynamic> toJson() => {
    'nodes': _nodes.toList(),
    'edges': _edges.map((k, v) => MapEntry(k, v.toList())),
  };
  void restore(Map<String, dynamic> j) {
    _nodes
      ..clear()
      ..addAll((j['nodes'] as List).cast<String>());
    _edges.clear();
    for (final e in (j['edges'] as Map).entries) {
      _edges[e.key as String] = (e.value as List).cast<String>().toSet();
    }
  }
}

class ConstraintDependencyGraph extends ConstraintGraph {}

class ConstraintGraphSet {
  final constraints = ConstraintGraph();
  final dependencies = ConstraintDependencyGraph();
  final references = ConstraintGraph();
  final construction = ConstraintGraph();
  Map<String, dynamic> toJson() => {
    'constraints': constraints.toJson(),
    'dependencies': dependencies.toJson(),
    'references': references.toJson(),
    'construction': construction.toJson(),
  };
  void restore(Map<String, dynamic> j) {
    constraints.restore(_map(j['constraints']));
    dependencies.restore(_map(j['dependencies']));
    references.restore(_map(j['references']));
    construction.restore(_map(j['construction']));
  }

  Map<String, dynamic> _map(Object? v) => (v as Map).cast<String, dynamic>();
}
