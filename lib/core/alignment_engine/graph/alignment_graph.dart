class AlignmentGraph {
  final Map<String, Set<String>> dependencies = {};
  final Map<String, List<List<double>>> transformHistory = {};
  final Map<String, Map<String, String>> referenceMappings = {};
  void add(String id) => dependencies.putIfAbsent(id, () => {});
  void connect(String parent, String child) {
    add(parent);
    add(child);
    if (parent == child || downstream(child).contains(parent)) {
      throw StateError('Circular alignment dependency');
    }
    dependencies[parent]!.add(child);
  }

  void recordTransform(String id, List<double> matrix) =>
      transformHistory.putIfAbsent(id, () => []).add(List.of(matrix));
  void mapReference(String id, String moving, String fixed) =>
      referenceMappings.putIfAbsent(id, () => {})[moving] = fixed;
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

  Set<String> upstream(String id) => {
    for (final e in dependencies.entries)
      if (e.value.contains(id)) ...{e.key, ...upstream(e.key)},
  };
}
