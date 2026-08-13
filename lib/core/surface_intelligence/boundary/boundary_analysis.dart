import '../models/surface_models.dart';

class BoundaryAnalysisEngine {
  const BoundaryAnalysisEngine();
  BoundaryReport analyze(List<BoundarySegment> segments) {
    if (segments.isEmpty) {
      return const BoundaryReport(
        loops: 0,
        openEdges: 0,
        regions: 0,
        crossings: 0,
        islands: 0,
        holes: 0,
        quality: 0,
      );
    }
    final adjacency = <String, Set<String>>{};
    final degree = <String, int>{};
    for (final e in segments) {
      adjacency.putIfAbsent(e.startId, () => {}).add(e.endId);
      adjacency.putIfAbsent(e.endId, () => {}).add(e.startId);
      degree.update(e.startId, (value) => value + 1, ifAbsent: () => 1);
      degree.update(e.endId, (value) => value + 1, ifAbsent: () => 1);
    }
    final open = degree.values.where((value) => value == 1).length;
    var components = 0;
    final visited = <String>{};
    for (final node in adjacency.keys) {
      if (visited.contains(node)) continue;
      components++;
      final queue = [node];
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        if (!visited.add(current)) continue;
        queue.addAll(adjacency[current]!.where((e) => !visited.contains(e)));
      }
    }
    final loops = open == 0 ? components : 0,
        crossings = segments.where((e) => e.crossing).length,
        regions = segments
            .map((e) => e.regionId)
            .whereType<String>()
            .toSet()
            .length,
        holes = (loops - 1).clamp(0, 1 << 20),
        penalty = (open + crossings) / (segments.length + 1);
    return BoundaryReport(
      loops: loops,
      openEdges: open,
      regions: regions,
      crossings: crossings,
      islands: (components - 1).clamp(0, 1 << 20),
      holes: holes,
      quality: (1 - penalty).clamp(0, 1),
    );
  }
}
