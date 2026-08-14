class ValidationGraph {
  final Map<String, Set<String>> dependencies = {},
      featureInfluence = {},
      referenceInfluence = {},
      regionInfluence = {},
      alignmentInfluence = {};
  void add(String id) => dependencies.putIfAbsent(id, () => {});
  void connect(String parent, String child) {
    add(parent);
    add(child);
    if (parent == child || downstream(child).contains(parent)) {
      throw StateError('Circular validation dependency');
    }
    dependencies[parent]!.add(child);
  }

  void influence(
    Map<String, Set<String>> graph,
    String source,
    String validation,
  ) => graph.putIfAbsent(source, () => {}).add(validation);
  Set<String> downstream(String id) {
    final out = <String>{};
    void visit(String n) {
      for (final c in dependencies[n] ?? const <String>{}) {
        if (out.add(c)) visit(c);
      }
    }

    visit(id);
    return out;
  }
}
