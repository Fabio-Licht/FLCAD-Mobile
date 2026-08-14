class FeatureGraph {
  final Set<String> nodes = {};
  final Map<String, Set<String>> edges = {};
  void add(String id) {
    nodes.add(id);
    edges.putIfAbsent(id, () => {});
  }

  void remove(String id) {
    nodes.remove(id);
    edges.remove(id);
    for (final e in edges.values) {
      e.remove(id);
    }
  }

  void connect(String dependency, String dependent) {
    if (!nodes.contains(dependency) || !nodes.contains(dependent)) {
      throw StateError('Unknown feature graph node');
    }
    if (dependency == dependent || _reaches(dependent, dependency)) {
      throw StateError(
        'Circular feature dependency: $dependency -> $dependent',
      );
    }
    edges[dependency]!.add(dependent);
  }

  bool _reaches(String from, String target, [Set<String>? visited]) {
    if (from == target) return true;
    final seen = visited ?? <String>{};
    if (!seen.add(from)) return false;
    return edges[from]?.any((n) => _reaches(n, target, seen)) ?? false;
  }

  Set<String> downstream(String id) {
    final out = <String>{};
    void visit(String n) {
      for (final x in edges[n] ?? const <String>{}) {
        if (out.add(x)) visit(x);
      }
    }

    visit(id);
    return out;
  }

  Set<String> upstream(String id) => {
    for (final e in edges.entries)
      if (e.value.contains(id)) ...{e.key, ...upstream(e.key)},
  };
  Map<String, dynamic> toJson() => {
    'nodes': nodes.toList(),
    'edges': edges.map((k, v) => MapEntry(k, v.toList())),
  };
}

class DependencyGraph extends FeatureGraph {}

class ExecutionGraph extends FeatureGraph {}

class ReferenceGraph extends FeatureGraph {}

class HistoryGraph extends FeatureGraph {}

class ParentGraph extends FeatureGraph {}

class ChildrenGraph extends FeatureGraph {}

class ImpactGraph extends FeatureGraph {}

class FeatureGraphSet {
  final dependencies = DependencyGraph(),
      execution = ExecutionGraph(),
      references = ReferenceGraph(),
      history = HistoryGraph(),
      parents = ParentGraph(),
      children = ChildrenGraph(),
      impact = ImpactGraph();
  Iterable<FeatureGraph> get all => [
    dependencies,
    execution,
    references,
    history,
    parents,
    children,
    impact,
  ];
  Map<String, dynamic> toJson() => {
    'dependencies': dependencies.toJson(),
    'execution': execution.toJson(),
    'references': references.toJson(),
    'history': history.toJson(),
    'parents': parents.toJson(),
    'children': children.toJson(),
    'impact': impact.toJson(),
  };
}
