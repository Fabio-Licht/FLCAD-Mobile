class StudioCommand {
  const StudioCommand({
    required this.id,
    required this.label,
    required this.category,
    required this.execute,
    this.keywords = const [],
    this.enabled = true,
  });
  final String id, label, category;
  final List<String> keywords;
  final bool enabled;
  final Future<void> Function() execute;
}

class StudioCommandManager {
  final Map<String, StudioCommand> _commands = {};
  void register(StudioCommand command) {
    if (_commands.containsKey(command.id)) {
      throw StateError('Command ${command.id} already registered');
    }
    _commands[command.id] = command;
  }

  Future<void> execute(String id) async {
    final c = _commands[id] ?? (throw StateError('Command $id not found'));
    if (!c.enabled) throw StateError('Command $id disabled');
    await c.execute();
  }

  List<StudioCommand> search(String query) {
    final q = query.trim().toLowerCase();
    return _commands.values
        .where(
          (c) =>
              q.isEmpty ||
              c.label.toLowerCase().contains(q) ||
              c.id.toLowerCase().contains(q) ||
              c.keywords.any((k) => k.toLowerCase().contains(q)),
        )
        .toList();
  }
}

class StudioTool {
  const StudioTool(this.id, this.label, this.commandId, this.contexts);
  final String id, label, commandId;
  final Set<String> contexts;
}

class ToolManager {
  final Map<String, StudioTool> _tools = {};
  void register(StudioTool tool) => _tools[tool.id] = tool;
  List<StudioTool> forContext(String context) => _tools.values
      .where((t) => t.contexts.contains(context) || t.contexts.contains('*'))
      .toList();
}
