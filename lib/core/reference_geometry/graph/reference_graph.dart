class ReferenceGraph {
  final Map<String, Set<String>> references = {};
  void add(String id) => references.putIfAbsent(id, () => {});
  void remove(String id) {
    references.remove(id);
    for (final children in references.values) {
      children.remove(id);
    }
  }

  void connect(String parent, String child) {
    add(parent);
    add(child);
    if (parent == child || downstream(child).contains(parent)) {
      throw StateError('Circular reference dependency');
    }
    references[parent]!.add(child);
  }

  Set<String> downstream(String id) {
    final out = <String>{};
    void visit(String n) {
      for (final child in references[n] ?? const <String>{}) {
        if (out.add(child)) visit(child);
      }
    }

    visit(id);
    return out;
  }

  Set<String> upstream(String id) => {
    for (final e in references.entries)
      if (e.value.contains(id)) ...{e.key, ...upstream(e.key)},
  };
  Set<String> impact(String id) => downstream(id);
}
