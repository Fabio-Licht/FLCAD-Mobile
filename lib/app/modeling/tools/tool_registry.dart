import 'active_tool.dart';

class ToolRegistry {
  final Map<String, ActiveTool> _tools = {};
  void register(ActiveTool tool) {
    if (_tools.containsKey(tool.id)) {
      throw StateError('Tool already registered: ${tool.id}');
    }
    _tools[tool.id] = tool;
  }

  ActiveTool resolve(String id) {
    final value = _tools[id];
    if (value == null) throw StateError('Tool is not registered: $id');
    return value;
  }

  Iterable<ActiveTool> get tools => _tools.values;
}
