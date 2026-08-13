enum EngineeringNodeKind {
  mesh,
  region,
  reference,
  sketch,
  surface,
  solid,
  fel,
  ai,
}

class EngineeringNode {
  const EngineeringNode(this.id, this.kind, this.metadata);
  final String id;
  final EngineeringNodeKind kind;
  final Map<String, dynamic> metadata;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'metadata': metadata,
  };
}

class EngineeringRelation {
  const EngineeringRelation(this.sourceId, this.targetId, this.relation);
  final String sourceId, targetId, relation;
  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'targetId': targetId,
    'relation': relation,
  };
}

class ReverseEngineeringKnowledgeGraph {
  ReverseEngineeringKnowledgeGraph();
  final Map<String, EngineeringNode> nodes = {};
  final List<EngineeringRelation> relations = [];
  void add(EngineeringNode node) => nodes[node.id] = node;
  void connect(String source, String target, String relation) {
    if (!nodes.containsKey(source) || !nodes.containsKey(target)) {
      throw StateError('Knowledge graph node missing');
    }
    if (!relations.any(
      (r) =>
          r.sourceId == source &&
          r.targetId == target &&
          r.relation == relation,
    )) {
      relations.add(EngineeringRelation(source, target, relation));
    }
  }

  Set<String> dependencies(String id) =>
      relations.where((r) => r.targetId == id).map((r) => r.sourceId).toSet();
  Set<String> impact(String id) {
    final result = <String>{}, queue = [id];
    while (queue.isNotEmpty) {
      final value = queue.removeLast();
      for (final relation in relations.where((r) => r.sourceId == value)) {
        if (result.add(relation.targetId)) queue.add(relation.targetId);
      }
    }
    return result;
  }

  void remove(String id) {
    nodes.remove(id);
    relations.removeWhere((r) => r.sourceId == id || r.targetId == id);
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'nodes': nodes.values.map((n) => n.toJson()).toList(),
    'relations': relations.map((r) => r.toJson()).toList(),
  };
  factory ReverseEngineeringKnowledgeGraph.fromJson(Map<String, dynamic> j) {
    final graph = ReverseEngineeringKnowledgeGraph();
    for (final raw in j['nodes'] as List? ?? const []) {
      final n = (raw as Map).cast<String, dynamic>();
      graph.add(
        EngineeringNode(
          n['id'] as String,
          EngineeringNodeKind.values.byName(n['kind'] as String),
          (n['metadata'] as Map? ?? const {}).cast(),
        ),
      );
    }
    for (final raw in j['relations'] as List? ?? const []) {
      final r = (raw as Map).cast<String, dynamic>();
      graph.relations.add(
        EngineeringRelation(
          r['sourceId'] as String,
          r['targetId'] as String,
          r['relation'] as String,
        ),
      );
    }
    return graph;
  }
}

typedef SurfaceGraph = ReverseEngineeringKnowledgeGraph;
