enum EngineeringPluginState { registered, initialized, active, stopped, failed }

class EngineeringPluginDescriptor {
  const EngineeringPluginDescriptor({
    required this.id,
    required this.version,
    this.dependencies = const {},
    this.compatiblePlatform = '>=1.0.0',
  });
  final String id, version, compatiblePlatform;
  final Map<String, String> dependencies;
}

abstract interface class EngineeringPlugin {
  EngineeringPluginDescriptor get descriptor;
  Future<void> initialize();
  Future<void> start();
  Future<void> stop();
}

class EngineeringPluginRegistry {
  final Map<String, EngineeringPlugin> _plugins = {};
  final Map<String, EngineeringPluginState> _states = {};
  void register(EngineeringPlugin plugin) {
    final id = plugin.descriptor.id;
    if (_plugins.containsKey(id)) {
      throw StateError('Plugin $id already registered');
    }
    _plugins[id] = plugin;
    _states[id] = EngineeringPluginState.registered;
  }

  Future<void> activate(String id) async {
    final plugin =
        _plugins[id] ?? (throw StateError('Plugin $id not registered'));
    for (final dependency in plugin.descriptor.dependencies.keys) {
      if (_states[dependency] != EngineeringPluginState.active) {
        throw StateError('Plugin $id requires active dependency $dependency');
      }
    }
    try {
      await plugin.initialize();
      _states[id] = EngineeringPluginState.initialized;
      await plugin.start();
      _states[id] = EngineeringPluginState.active;
    } catch (_) {
      _states[id] = EngineeringPluginState.failed;
      rethrow;
    }
  }

  Future<void> deactivate(String id) async {
    final plugin = _plugins[id];
    if (plugin == null) return;
    await plugin.stop();
    _states[id] = EngineeringPluginState.stopped;
  }

  EngineeringPluginState? stateOf(String id) => _states[id];
  Iterable<EngineeringPluginDescriptor> get descriptors =>
      _plugins.values.map((e) => e.descriptor);
}
