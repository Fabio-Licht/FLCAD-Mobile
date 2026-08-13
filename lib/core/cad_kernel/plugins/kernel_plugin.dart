import '../api/geometry_kernel_api.dart';

abstract interface class KernelPlugin {
  String get pluginId;
  String get pluginVersion;
  bool get compatible;
  GeometryKernelAPI createKernel();
}

class KernelPluginRegistry {
  final Map<String, KernelPlugin> _plugins = {};
  void register(KernelPlugin plugin) {
    if (!plugin.compatible) {
      throw StateError('Kernel plugin ${plugin.pluginId} incompatible');
    }
    if (_plugins.containsKey(plugin.pluginId)) {
      throw StateError('Kernel plugin ${plugin.pluginId} already registered');
    }
    _plugins[plugin.pluginId] = plugin;
  }

  KernelPlugin? remove(String id) => _plugins.remove(id);
  List<KernelPlugin> get plugins => List.unmodifiable(_plugins.values);
}
