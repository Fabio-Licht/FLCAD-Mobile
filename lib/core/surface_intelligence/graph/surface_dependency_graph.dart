enum SurfaceRelation { dependency, continuity, reference, neighbor, influence }

class SurfaceGraphEdge {
  const SurfaceGraphEdge(
    this.sourceId,
    this.targetId,
    this.relation, {
    this.weight = 1,
  });
  final String sourceId, targetId;
  final SurfaceRelation relation;
  final double weight;
  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'targetId': targetId,
    'relation': relation.name,
    'weight': weight,
  };
}

class SurfaceDependencyGraph {
  final Set<String> nodes = {};
  final List<SurfaceGraphEdge> edges = [];
  void add(String id) => nodes.add(id);
  void connect(SurfaceGraphEdge edge) {
    if (!nodes.contains(edge.sourceId) || !nodes.contains(edge.targetId)) {
      throw StateError('Surface graph node missing');
    }
    if (edge.relation == SurfaceRelation.dependency &&
        downstream(edge.targetId).contains(edge.sourceId)) {
      throw StateError('Surface dependency cycle');
    }
    edges.add(edge);
  }

  Set<String> downstream(String id) {
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
    'nodes': nodes.toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };
}
