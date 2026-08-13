class KnowledgeNode {
  const KnowledgeNode(this.id, this.kind, this.attributes);
  final String id, kind;
  final Map<String, dynamic> attributes;
}

class KnowledgeRelation {
  const KnowledgeRelation(this.from, this.to, this.kind);
  final String from, to, kind;
}

class ReverseKnowledgeGraph {
  final Map<String, KnowledgeNode> _nodes = {};
  final List<KnowledgeRelation> _relations = [];
  Iterable<KnowledgeNode> get nodes => _nodes.values;
  List<KnowledgeRelation> get relations => List.unmodifiable(_relations);
  void upsert(KnowledgeNode node) => _nodes[node.id] = node;
  void relate(String from, String to, String kind) {
    if (!_nodes.containsKey(from) || !_nodes.containsKey(to)) {
      throw StateError('Both knowledge nodes must exist');
    }
    _relations.add(KnowledgeRelation(from, to, kind));
  }
}
