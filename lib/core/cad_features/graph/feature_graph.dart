import '../models/feature_models.dart';

class FeatureGraph {
  final Map<String, CadFeature> nodes = {};
  final Map<String, Set<String>> dependencies = {};
  void add(CadFeature feature) {
    if (nodes.containsKey(feature.id) &&
        nodes[feature.id]!.revision >= feature.revision) {
      throw StateError('Feature revision must increase');
    }
    nodes[feature.id] = feature;
    dependencies[feature.id] = feature.dependencies.toSet();
    _ensureAcyclic();
  }

  Set<String> downstream(String id) {
    final result = <String>{}, queue = <String>[id];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final entry in dependencies.entries.where(
        (e) => e.value.contains(current),
      )) {
        if (result.add(entry.key)) queue.add(entry.key);
      }
    }
    return result;
  }

  Set<String> affectedByShape(String shapeId) {
    final direct = nodes.values
        .where((e) => e.inputs.any((s) => s.persistentId == shapeId))
        .map((e) => e.id)
        .toSet();
    return {...direct, ...direct.expand(downstream)};
  }

  void _ensureAcyclic() {
    for (final id in nodes.keys) {
      if (downstream(id).contains(id)) throw StateError('Feature graph cycle');
    }
  }

  Map<String, dynamic> toJson() => {
    'features': nodes.values.map((e) => e.toJson()).toList(),
    'dependencies': dependencies.map((k, v) => MapEntry(k, v.toList())),
  };
}
