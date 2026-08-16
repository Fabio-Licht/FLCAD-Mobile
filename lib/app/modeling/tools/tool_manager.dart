import '../interaction/interaction_context.dart';
import 'active_tool.dart';
import 'tool_registry.dart';

class ToolManager {
  ToolManager(this.registry);
  final ToolRegistry registry;
  ActiveTool? active;
  ActiveTool activate(String id, List<ModelingSelection> selection) {
    final tool = registry.resolve(id);
    if (selection.isEmpty) {
      throw StateError(
        'A selection is required before activating ${tool.label}.',
      );
    }
    if (selection.any((e) => !tool.allowedSelection.contains(e.type))) {
      throw StateError('The current selection is not valid for ${tool.label}.');
    }
    return active = tool;
  }

  void cancel() => active = null;
}
