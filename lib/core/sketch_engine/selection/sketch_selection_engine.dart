import '../analytics/sketch_analytics.dart';
import '../entities/sketch_entities.dart';

class SketchSelectionFilter {
  const SketchSelectionFilter({
    this.types,
    this.layer,
    this.construction,
    this.reference,
  });
  final Set<SketchEntityType>? types;
  final String? layer;
  final bool? construction;
  final bool? reference;
  bool accepts(SketchEntity e) =>
      (types == null || types!.contains(e.type)) &&
      (layer == null || e.metadata['layer'] == layer) &&
      (construction == null || e.construction == construction) &&
      (reference == null || e.reference == reference);
}

class SketchSelectionEngine {
  SketchSelectionEngine(this.analytics);
  final SketchAnalytics analytics;
  final Set<String> selected = {};
  String? hovered;
  String? preselected;
  void hover(SketchEntity? e) {
    hovered = e?.id;
    if (e != null) e.selectionState = SketchSelectionState.hovered;
  }

  void preselect(SketchEntity? e) {
    preselected = e?.id;
    if (e != null) e.selectionState = SketchSelectionState.preselected;
  }

  void select(SketchEntity e, {bool multi = false}) {
    if (!multi) selected.clear();
    selected.add(e.id);
    e.selectionState = SketchSelectionState.selected;
    analytics.selections++;
  }

  List<SketchEntity> window(
    Iterable<SketchEntity> entities,
    SketchSelectionFilter filter, {
    bool crossing = false,
  }) => entities.where(filter.accepts).toList();
  SketchEntity? priority(
    Iterable<SketchEntity> entities,
    Map<SketchEntityType, int> priorities,
  ) {
    final values = entities.toList()
      ..sort(
        (a, b) => (priorities[b.type] ?? 0).compareTo(priorities[a.type] ?? 0),
      );
    return values.firstOrNull;
  }
}
