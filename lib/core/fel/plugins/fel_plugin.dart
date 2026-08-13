import '../commands/fel_command.dart';

class FELPlugin {
  const FELPlugin({
    required this.id,
    required this.version,
    required this.commands,
  });
  final String id, version;
  final List<FELCommand> commands;
}

class FELPluginManager {
  final Map<String, FELPlugin> _plugins = {};
  void load(FELPlugin plugin, FELCommandRegistry registry) {
    _plugins[plugin.id] = plugin;
    for (final command in plugin.commands) {
      registry.register(command);
    }
  }

  void unload(String id, FELCommandRegistry registry) {
    final plugin = _plugins.remove(id);
    if (plugin != null) {
      for (final command in plugin.commands) {
        registry.unregister(command.name);
      }
    }
  }

  List<FELPlugin> get plugins => List.unmodifiable(_plugins.values);
}
