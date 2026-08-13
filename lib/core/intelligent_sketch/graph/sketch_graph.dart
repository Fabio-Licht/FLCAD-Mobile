class SketchGraphEdge {
  const SketchGraphEdge(this.sourceId, this.targetId, this.relation);
  final String sourceId, targetId, relation;
  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'targetId': targetId,
    'relation': relation,
  };
}

class SketchGraph {
  SketchGraph();
  final Set<String> nodes = {};
  final List<SketchGraphEdge> edges = [];
  void add(String id) => nodes.add(id);
  void connect(String source, String target, String relation) {
    if (!nodes.contains(source) || !nodes.contains(target)) {
      throw StateError('Sketch graph node missing');
    }
    if (!edges.any(
      (e) =>
          e.sourceId == source &&
          e.targetId == target &&
          e.relation == relation,
    )) {
      edges.add(SketchGraphEdge(source, target, relation));
    }
  }

  void remove(String id) {
    nodes.remove(id);
    edges.removeWhere((e) => e.sourceId == id || e.targetId == id);
  }

  Set<String> dependents(String id) {
    final result = <String>{}, queue = [id];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final edge in edges.where((e) => e.sourceId == current)) {
        if (result.add(edge.targetId)) queue.add(edge.targetId);
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'nodes': nodes.toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };
  factory SketchGraph.fromJson(Map<String, dynamic> j) {
    final g = SketchGraph()
      ..nodes.addAll((j['nodes'] as List? ?? const []).cast());
    for (final raw in j['edges'] as List? ?? const []) {
      final e = (raw as Map).cast<String, dynamic>();
      g.edges.add(
        SketchGraphEdge(
          e['sourceId'] as String,
          e['targetId'] as String,
          e['relation'] as String,
        ),
      );
    }
    return g;
  }
}
