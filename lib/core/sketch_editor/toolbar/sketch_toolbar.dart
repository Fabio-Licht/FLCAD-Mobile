import '../models/editor_models.dart';

class SketchToolbar {
  SketchToolType? activeTool;
  final Set<SketchToolType> enabled = SketchToolType.values.toSet();
  void activate(SketchToolType tool) {
    if (!enabled.contains(tool)) {
      throw StateError('Tool disabled: ${tool.name}');
    }
    activeTool = tool;
  }

  void deactivate() => activeTool = null;
  void setEnabled(SketchToolType tool, bool value) =>
      value ? enabled.add(tool) : enabled.remove(tool);
}
