import 'ai_plugin.dart';
import '../providers/ai_provider.dart';

class PluginManager {
  final Map<String, AIPlugin> _plugins = {};
  final Map<String, AIProvider> _providers = {};
  List<AIPlugin> get plugins => List.unmodifiable(_plugins.values);
  void register(AIPlugin plugin) => _plugins[plugin.id] = plugin;
  AIPlugin? unload(String id) => _plugins.remove(id);
  AIPlugin? find(String id) => _plugins[id];
  List<AIProvider> get providers => List.unmodifiable(_providers.values);
  void registerProvider(AIProvider provider) =>
      _providers[provider.id] = provider;
  AIProvider? unloadProvider(String id) => _providers.remove(id);
}
