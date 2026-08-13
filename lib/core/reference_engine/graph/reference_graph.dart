class ReferenceGraphEdge {
  const ReferenceGraphEdge(this.sourceId, this.targetId, this.relation);
  final String sourceId, targetId, relation;
  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'targetId': targetId,
    'relation': relation,
  };
}

class ReferenceGraph {
  ReferenceGraph();
  final Set<String> nodes = {};
  final List<ReferenceGraphEdge> edges = [];
  void add(String id) => nodes.add(id);
  void connect(String source, String target, String relation) {
    if (!nodes.contains(source) || !nodes.contains(target)) {
      throw StateError('Reference graph node missing');
    }
    edges.add(ReferenceGraphEdge(source, target, relation));
  }

  void remove(String id) {
    nodes.remove(id);
    edges.removeWhere((edge) => edge.sourceId == id || edge.targetId == id);
  }

  Set<String> dependents(String id) {
    final result = <String>{}, queue = <String>[id];
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

  factory ReferenceGraph.fromJson(Map<String, dynamic> json) {
    final graph = ReferenceGraph();
    graph.nodes.addAll((json['nodes'] as List? ?? const []).cast<String>());
    for (final value in (json['edges'] as List? ?? const [])) {
      final edge = (value as Map).cast<String, dynamic>();
      graph.edges.add(
        ReferenceGraphEdge(
          edge['sourceId'] as String,
          edge['targetId'] as String,
          edge['relation'] as String,
        ),
      );
    }
    return graph;
  }
}
