class CognitionNode {
  const CognitionNode(this.id, this.kind, this.attributes);
  final String id, kind;
  final Map<String, dynamic> attributes;
}

class CognitionEdge {
  const CognitionEdge(this.from, this.to, this.relation, this.confidence);
  final String from, to, relation;
  final double confidence;
}

class EngineeringCognitionGraph {
  final Map<String, CognitionNode> nodes = {};
  final List<CognitionEdge> edges = [];
  void add(CognitionNode node) => nodes[node.id] = node;
  void connect(CognitionEdge edge) {
    if (!nodes.containsKey(edge.from) || !nodes.containsKey(edge.to)) {
      throw StateError('Cognition graph endpoints must exist');
    }
    if (!edges.any(
      (e) =>
          e.from == edge.from && e.to == edge.to && e.relation == edge.relation,
    )) {
      edges.add(edge);
    }
  }

  List<CognitionEdge> outgoing(String id) =>
      edges.where((e) => e.from == id).toList();
}
