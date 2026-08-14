class IntelligenceGraph {
  final Map<String, Set<String>> relations = {},
      featureRelations = {},
      referenceRelations = {},
      validationRelations = {},
      alignmentRelations = {},
      qualityRelations = {},
      impactRelations = {};
  void add(String id) => relations.putIfAbsent(id, () => {});
  void connect(String parent, String child) {
    add(parent);
    add(child);
    if (parent == child || downstream(child).contains(parent)) {
      throw StateError('Circular intelligence dependency');
    }
    relations[parent]!.add(child);
  }

  void relate(Map<String, Set<String>> graph, String source, String target) =>
      graph.putIfAbsent(source, () => {}).add(target);
  Set<String> downstream(String id) {
    final out = <String>{};
    void visit(String n) {
      for (final c in relations[n] ?? const <String>{}) {
        if (out.add(c)) visit(c);
      }
    }

    visit(id);
    return out;
  }
}
