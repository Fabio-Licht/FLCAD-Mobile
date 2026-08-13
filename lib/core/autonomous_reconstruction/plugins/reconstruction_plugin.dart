import '../models/reconstruction_models.dart';

abstract interface class ReconstructionPlannerPlugin {
  String get id;
  String get version;
  List<ReconstructionStage> enrich(ReconstructionWorkflow workflow);
}

class ReconstructionPluginRegistry {
  final Map<String, ReconstructionPlannerPlugin> _plugins = {};
  void register(ReconstructionPlannerPlugin plugin) {
    if (_plugins.containsKey(plugin.id)) {
      throw StateError('Reconstruction plugin already registered');
    }
    _plugins[plugin.id] = plugin;
  }

  ReconstructionPlannerPlugin? unregister(String id) => _plugins.remove(id);
  Iterable<ReconstructionPlannerPlugin> get plugins => _plugins.values;
}
