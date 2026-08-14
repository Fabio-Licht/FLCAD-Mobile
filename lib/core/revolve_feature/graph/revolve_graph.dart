class RevolveGraph {
  final Map<String, Set<String>> dependencies = {};
  void add(String id) => dependencies.putIfAbsent(id, () => {});
  void connect(String parent, String child) {
    add(parent);
    add(child);
    if (parent == child || downstream(child).contains(parent)) {
      throw StateError('Circular revolve dependency');
    }
    dependencies[parent]!.add(child);
  }

  Set<String> downstream(String id) {
    final out = <String>{};
    void visit(String n) {
      for (final x in dependencies[n] ?? const <String>{}) {
        if (out.add(x)) visit(x);
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
