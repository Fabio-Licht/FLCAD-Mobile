import '../../sketch_engine/entities/sketch_entities.dart';
import '../analytics/editor_analytics.dart';

class EditorSelectionFilter {
  const EditorSelectionFilter({
    this.types,
    this.construction,
    this.reference,
    this.layer,
  });
  final Set<SketchEntityType>? types;
  final bool? construction, reference;
  final String? layer;
  bool accepts(SketchEntity e) =>
      (types == null || types!.contains(e.type)) &&
      (construction == null || e.construction == construction) &&
      (reference == null || e.reference == reference) &&
      (layer == null || e.metadata['layer'] == layer);
}

class SelectionSnapshot {
  const SelectionSnapshot(this.ids, this.timestamp);
  final Set<String> ids;
  final DateTime timestamp;
}

class EditorSelectionEngine {
  EditorSelectionEngine(this.analytics);
  final EditorAnalytics analytics;
  final Set<String> selected = {}, persistent = {};
  final Map<String, Set<String>> groups = {};
  final List<SelectionSnapshot> history = [];
  String? hovered, preselected, previewed, highlighted;
  void select(SketchEntity entity, {bool multi = false, bool persist = false}) {
    if (!multi) selected.clear();
    selected.add(entity.id);
    if (persist) persistent.add(entity.id);
    entity.selectionState = SketchSelectionState.selected;
    _record();
  }

  void selectMany(
    Iterable<SketchEntity> entities, {
    bool crossing = false,
    EditorSelectionFilter filter = const EditorSelectionFilter(),
  }) {
    for (final e in entities.where(filter.accepts)) {
      selected.add(e.id);
    }
    _record();
  }

  List<SketchEntity> window(
    Iterable<SketchEntity> entities,
    EditorSelectionFilter filter, {
    bool crossing = false,
  }) => entities.where(filter.accepts).toList();
  SketchEntity? priority(
    Iterable<SketchEntity> entities,
    Map<SketchEntityType, int> priority,
  ) {
    final values = entities.toList()
      ..sort(
        (a, b) => (priority[b.type] ?? 0).compareTo(priority[a.type] ?? 0),
      );
    return values.firstOrNull;
  }

  void hover(SketchEntity? entity) {
    hovered = entity?.id;
    if (entity != null) entity.selectionState = SketchSelectionState.hovered;
  }

  void preselect(SketchEntity? entity) {
    preselected = entity?.id;
    if (entity != null) {
      entity.selectionState = SketchSelectionState.preselected;
    }
  }

  void preview(String? id) => previewed = id;
  void highlight(String? id) => highlighted = id;
  void createGroup(String name, Iterable<String> ids) =>
      groups[name] = ids.toSet();
  void restorePersistent() {
    selected
      ..clear()
      ..addAll(persistent);
    _record();
  }

  void clear() {
    selected.clear();
    _record();
  }

  void _record() {
    analytics.selections++;
    history.add(SelectionSnapshot(Set.of(selected), DateTime.now().toUtc()));
  }
}
