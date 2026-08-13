enum EngineeringNodeType {
  project,
  mesh,
  pointCloud,
  region,
  reference,
  sketch,
  surface,
  topology,
  feature,
  solid,
  cam,
  inspection,
  ai,
}

class EngineeringGraphNode {
  const EngineeringGraphNode(this.id, this.type, {this.metadata = const {}});
  final String id;
  final EngineeringNodeType type;
  final Map<String, dynamic> metadata;
}

class EngineeringGraphEdge {
  const EngineeringGraphEdge(
    this.sourceId,
    this.targetId,
    this.relation, {
    this.metadata = const {},
  });
  final String sourceId, targetId, relation;
  final Map<String, dynamic> metadata;
}

class EngineeringGraph {
  final Map<String, EngineeringGraphNode> nodes = {};
  final List<EngineeringGraphEdge> edges = [];
  void addNode(EngineeringGraphNode node) => nodes[node.id] = node;
  void connect(EngineeringGraphEdge edge) {
    if (!nodes.containsKey(edge.sourceId) ||
        !nodes.containsKey(edge.targetId)) {
      throw StateError('Engineering graph node missing');
    }
    if (_createsCycle(edge.sourceId, edge.targetId)) {
      throw StateError('Engineering graph cycle detected');
    }
    edges.add(edge);
  }

  Set<String> dependencies(String id) =>
      edges.where((e) => e.targetId == id).map((e) => e.sourceId).toSet();
  Set<String> impact(String id) {
    final result = <String>{}, queue = [id];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final edge in edges.where((e) => e.sourceId == current)) {
        if (result.add(edge.targetId)) queue.add(edge.targetId);
      }
    }
    return result;
  }

  bool _createsCycle(String source, String target) =>
      source == target || impact(target).contains(source);
}
