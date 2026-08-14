class TransitionGraph {
  final Map<String, Set<String>> dependencies = {};
  void add(String id) => dependencies.putIfAbsent(id, () => {});
  void connect(String parent, String child) {
    add(parent);
    add(child);
    if (parent == child || downstream(child).contains(parent)) {
      throw StateError('Circular transition dependency');
    }
    dependencies[parent]!.add(child);
  }

  Set<String> downstream(String id) {
    final result = <String>{};
    void visit(String n) {
      for (final child in dependencies[n] ?? const <String>{}) {
        if (result.add(child)) visit(child);
      }
    }

    visit(id);
    return result;
  }

  Set<String> upstream(String id) => {
    for (final e in dependencies.entries)
      if (e.value.contains(id)) ...{e.key, ...upstream(e.key)},
  };
}
