import '../models/studio_models.dart';

class EngineeringTreeManager {
  final Map<String, EngineeringTreeNode> _nodes = {};
  List<EngineeringTreeNode> get nodes => List.unmodifiable(_nodes.values);
  void add(EngineeringTreeNode node) {
    if (node.parentId != null && !_nodes.containsKey(node.parentId)) {
      throw StateError('Parent ${node.parentId} not found');
    }
    _nodes[node.id] = node;
  }

  void visibility(String id, bool value) =>
      _replace(id, (n) => n.copyWith(visible: value));
  void lock(String id, bool value) =>
      _replace(id, (n) => n.copyWith(locked: value));
  void select(Set<String> ids) {
    for (final entry in _nodes.entries.toList()) {
      _nodes[entry.key] = entry.value.copyWith(
        selected: ids.contains(entry.key),
      );
    }
  }

  List<EngineeringTreeNode> children(String? parent) =>
      nodes.where((n) => n.parentId == parent).toList();
  void _replace(
    String id,
    EngineeringTreeNode Function(EngineeringTreeNode) value,
  ) {
    final node = _nodes[id] ?? (throw StateError('Node $id not found'));
    _nodes[id] = value(node);
  }
}
