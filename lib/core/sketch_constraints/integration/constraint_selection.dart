enum ConstraintHighlight { normal, selected, conflict, dependency, preview }

class ConstraintSelection {
  final Set<String> selectedConstraints = {}, selectedEntities = {};
  final Map<String, ConstraintHighlight> highlights = {};
  void selectConstraint(String id, {bool multi = false}) {
    if (!multi) selectedConstraints.clear();
    selectedConstraints.add(id);
    highlights[id] = ConstraintHighlight.selected;
  }

  void selectEntity(String id, {bool multi = false}) {
    if (!multi) selectedEntities.clear();
    selectedEntities.add(id);
  }

  void highlightConflict(Iterable<String> ids) {
    for (final id in ids) {
      highlights[id] = ConstraintHighlight.conflict;
    }
  }

  void highlightDependencies(Iterable<String> ids) {
    for (final id in ids) {
      highlights[id] = ConstraintHighlight.dependency;
    }
  }

  void preview(String id) => highlights[id] = ConstraintHighlight.preview;
}
