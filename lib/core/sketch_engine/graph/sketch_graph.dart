class SketchGraph {
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
    for (final e in _edges.values) {
      e.remove(id);
    }
  }

  void connect(String from, String to) {
    if (!_nodes.contains(from) || !_nodes.contains(to)) {
      throw StateError('Unknown sketch graph node');
    }
    if (from == to || _reachable(to, from)) {
      throw StateError('Sketch graph cycle detected');
    }
    _edges[from]!.add(to);
  }

  bool _reachable(String from, String target, [Set<String>? seen]) {
    if (from == target) return true;
    final visited = seen ?? <String>{};
    if (!visited.add(from)) return false;
    return _edges[from]?.any((next) => _reachable(next, target, visited)) ??
        false;
  }

  Map<String, dynamic> toJson() => {
    'nodes': _nodes.toList(),
    'edges': _edges.map((k, v) => MapEntry(k, v.toList())),
  };
  void restore(Map<String, dynamic> json) {
    _nodes
      ..clear()
      ..addAll((json['nodes'] as List).cast<String>());
    _edges.clear();
    for (final e in (json['edges'] as Map).entries) {
      _edges[e.key as String] = (e.value as List).cast<String>().toSet();
    }
  }
}

class EntityGraph extends SketchGraph {}

class DependencyGraph extends SketchGraph {}

class ReferenceGraph extends SketchGraph {}

class ConstructionGraph extends SketchGraph {}

class SketchGraphSet {
  final sketch = SketchGraph();
  final entities = EntityGraph();
  final dependencies = DependencyGraph();
  final references = ReferenceGraph();
  final construction = ConstructionGraph();
  Map<String, dynamic> toJson() => {
    'sketch': sketch.toJson(),
    'entities': entities.toJson(),
    'dependencies': dependencies.toJson(),
    'references': references.toJson(),
    'construction': construction.toJson(),
  };
  void restore(Map<String, dynamic> json) {
    sketch.restore(_map(json['sketch']));
    entities.restore(_map(json['entities']));
    dependencies.restore(_map(json['dependencies']));
    references.restore(_map(json['references']));
    construction.restore(_map(json['construction']));
  }

  Map<String, dynamic> _map(Object? value) =>
      (value as Map).cast<String, dynamic>();
}
