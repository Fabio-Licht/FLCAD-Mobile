class ProfileGraph {
  final Set<String> nodes = {};
  final Map<String, Set<String>> edges = {};
  void add(String id) {
    nodes.add(id);
    edges.putIfAbsent(id, () => {});
  }

  void connect(String a, String b) {
    if (!nodes.contains(a) || !nodes.contains(b)) {
      throw StateError('Unknown topology node');
    }
    if (a == b) throw StateError('Topology self edge');
    edges[a]!.add(b);
  }

  void remove(String id) {
    nodes.remove(id);
    edges.remove(id);
    for (final e in edges.values) {
      e.remove(id);
    }
  }

  Map<String, dynamic> toJson() => {
    'nodes': nodes.toList(),
    'edges': edges.map((k, v) => MapEntry(k, v.toList())),
  };
}

class LoopGraph extends ProfileGraph {}

class RegionGraph extends ProfileGraph {}

class TopologyGraph extends ProfileGraph {}

class AdjacencyGraph extends ProfileGraph {}

class ContainmentGraph extends ProfileGraph {}

class ProfileGraphSet {
  final profiles = ProfileGraph(),
      loops = LoopGraph(),
      regions = RegionGraph(),
      topology = TopologyGraph(),
      adjacency = AdjacencyGraph(),
      containment = ContainmentGraph();
  Map<String, dynamic> toJson() => {
    'profiles': profiles.toJson(),
    'loops': loops.toJson(),
    'regions': regions.toJson(),
    'topology': topology.toJson(),
    'adjacency': adjacency.toJson(),
    'containment': containment.toJson(),
  };
}
