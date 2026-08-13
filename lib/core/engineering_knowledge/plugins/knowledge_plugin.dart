import '../knowledge/knowledge_library.dart';
import '../rules/engineering_rules.dart';

abstract interface class EngineeringKnowledgePlugin {
  String get id;
  String get version;
  KnowledgeLibrary knowledge();
  List<EngineeringRule> rules();
}

class KnowledgePluginRegistry {
  final Map<String, EngineeringKnowledgePlugin> _plugins = {};
  Iterable<EngineeringKnowledgePlugin> get plugins => _plugins.values;
  void register(EngineeringKnowledgePlugin plugin) {
    if (_plugins.containsKey(plugin.id)) {
      throw StateError('Knowledge plugin already registered: ${plugin.id}');
    }
    _plugins[plugin.id] = plugin;
  }

  EngineeringKnowledgePlugin? unregister(String id) => _plugins.remove(id);
  KnowledgeLibrary aggregate() {
    final result = KnowledgeLibrary();
    for (final p in _plugins.values) {
      result.merge(p.knowledge());
    }
    return result;
  }
}
