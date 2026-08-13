import '../models/cognition_models.dart';

abstract interface class CognitionPlugin {
  String get id;
  String get version;
  List<RecognizedFeature> enrich(CognitionSnapshot snapshot);
}

class CognitionPluginRegistry {
  final Map<String, CognitionPlugin> _plugins = {};
  Iterable<CognitionPlugin> get plugins => _plugins.values;
  void register(CognitionPlugin plugin) {
    if (_plugins.containsKey(plugin.id)) {
      throw StateError('Cognition plugin already registered');
    }
    _plugins[plugin.id] = plugin;
  }

  CognitionPlugin? unregister(String id) => _plugins.remove(id);
}
