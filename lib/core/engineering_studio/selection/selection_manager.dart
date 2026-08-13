import '../models/studio_models.dart';

abstract interface class LassoSelectionBackend {
  Future<Set<String>> select(List<(double, double)> polygon);
}

class SelectionManager {
  StudioSelection _selection = const StudioSelection(
    {},
    SelectionMode.single,
    {},
  );
  StudioSelection get selection => _selection;
  void select(String id, {bool additive = false}) {
    final ids = additive ? {..._selection.ids, id} : {id};
    _selection = StudioSelection(
      ids,
      additive ? SelectionMode.multiple : SelectionMode.single,
      _selection.filter,
    );
  }

  void selectMany(Iterable<String> ids, SelectionMode mode) =>
      _selection = StudioSelection(ids.toSet(), mode, _selection.filter);
  void filter(Set<StudioEntityType> types) =>
      _selection = StudioSelection(_selection.ids, _selection.mode, types);
  void invert(Iterable<String> available) => _selection = StudioSelection(
    available.toSet().difference(_selection.ids),
    SelectionMode.multiple,
    _selection.filter,
  );
  void similar(String id, Iterable<EngineeringTreeNode> nodes) {
    final source = nodes.firstWhere((n) => n.id == id);
    selectMany(
      nodes.where((n) => n.type == source.type).map((n) => n.id),
      SelectionMode.multiple,
    );
  }

  void byConfidence(Iterable<EngineeringTreeNode> nodes, double minimum) =>
      selectMany(
        nodes.where((n) => n.confidence >= minimum).map((n) => n.id),
        SelectionMode.multiple,
      );
  void byType(Iterable<EngineeringTreeNode> nodes, StudioEntityType type) =>
      selectMany(
        nodes.where((n) => n.type == type).map((n) => n.id),
        SelectionMode.multiple,
      );
  void expand(Map<String, Set<String>> adjacency) => selectMany({
    ..._selection.ids,
    ..._selection.ids.expand((id) => adjacency[id] ?? {}),
  }, SelectionMode.multiple);
  void shrink(Map<String, Set<String>> adjacency) {
    final keep = _selection.ids.where(
      (id) => (adjacency[id] ?? {}).every(_selection.ids.contains),
    );
    selectMany(keep, SelectionMode.multiple);
  }

  void clear() =>
      _selection = const StudioSelection({}, SelectionMode.single, {});
}
