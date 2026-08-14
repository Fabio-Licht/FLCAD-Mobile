import '../models/interactive_models.dart';

class SelectionManager {
  final Map<String, InteractiveSelection> selections = {};
  String? activeId;
  InteractiveSelection select(InteractiveSelection selection) {
    selections[selection.id] = selection;
    activeId = selection.id;
    return selection;
  }

  InteractiveSelection get active =>
      selections[activeId] ??
      (throw StateError('No active interactive selection'));
  void clear() => activeId = null;
}
