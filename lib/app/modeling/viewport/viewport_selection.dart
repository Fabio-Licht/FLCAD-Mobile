import '../interaction/interaction_context.dart';

enum SelectionModifier { replace, control, shift }

class ViewportSelection {
  const ViewportSelection();
  List<ModelingSelection> apply(
    List<ModelingSelection> current,
    ModelingSelection target,
    SelectionModifier modifier,
  ) {
    if (modifier == SelectionModifier.replace) return [target];
    final result = [...current];
    final index = result.indexWhere((e) => e.id == target.id);
    if (modifier == SelectionModifier.control && index >= 0) {
      result.removeAt(index);
    } else if (index < 0) {
      result.add(target);
    }
    return List.unmodifiable(result);
  }
}
