enum RegionNodeType { region, plane, axis, curve, sketch, surface, fillet }

class RegionGraphNode {
  const RegionGraphNode(this.id, this.type, this.referenceId);
  final String id, referenceId;
  final RegionNodeType type;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'referenceId': referenceId,
  };
}

class RegionGraphEdge {
  const RegionGraphEdge(
    this.from,
    this.to,
    this.relation, {
    this.sharedBoundary = 0,
  });
  final String from, to, relation;
  final int sharedBoundary;
  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'relation': relation,
    'sharedBoundary': sharedBoundary,
  };
}

class RegionGraph {
  final Map<String, RegionGraphNode> nodes = {};
  final List<RegionGraphEdge> edges = [];
  void addNode(RegionGraphNode node) => nodes[node.id] = node;
  void connect(RegionGraphEdge edge) {
    if (!nodes.containsKey(edge.from) || !nodes.containsKey(edge.to)) {
      throw StateError('Graph node missing');
    }
    edges.add(edge);
  }

  Set<String> dependentsOf(String id) {
    final result = <String>{}, queue = <String>[id];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final edge in edges.where((e) => e.from == current)) {
        if (result.add(edge.to)) queue.add(edge.to);
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'nodes': nodes.values.map((e) => e.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };
}
