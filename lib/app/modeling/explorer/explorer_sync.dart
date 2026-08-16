import '../interaction/interaction_context.dart';
import '../viewport/viewport_controller.dart';

class ExplorerSync {
  const ExplorerSync(this.viewport);
  final ModelingViewportController viewport;
  void select(ModelingSelection entity, {bool additive = false}) =>
      viewport.selectFromExplorer(entity, additive: additive);
  List<String> get selectedIds =>
      viewport.selection.map((e) => e.id).toList(growable: false);
}
