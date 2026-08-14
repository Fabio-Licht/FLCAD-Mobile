import '../api/geometry_kernel_api.dart';
import '../models/kernel_models.dart';
import '../plugins/kernel_plugin.dart';

class KernelManager {
  KernelManager({KernelPluginRegistry? plugins})
    : plugins = plugins ?? KernelPluginRegistry();
  final KernelPluginRegistry plugins;
  final Map<String, GeometryKernelAPI> _kernels = {};
  String? activeId;
  GeometryKernelAPI get active => activeId == null
      ? const UnavailableGeometryKernel()
      : _kernels[activeId] ?? const UnavailableGeometryKernel();
  void register(GeometryKernelAPI kernel, {bool makeDefault = false}) {
    if (_kernels.containsKey(kernel.descriptor.id)) {
      throw StateError('Kernel ${kernel.descriptor.id} already registered');
    }
    _kernels[kernel.descriptor.id] = kernel;
    if (makeDefault && activeId == null) activeId = kernel.descriptor.id;
  }

  void loadPlugin(String pluginId, {bool makeDefault = false}) {
    final plugin =
        plugins.plugins.where((p) => p.pluginId == pluginId).firstOrNull ??
        (throw StateError('Plugin $pluginId not found'));
    register(plugin.createKernel(), makeDefault: makeDefault);
  }

  Future<KernelHealth> select(String id) async {
    final kernel =
            _kernels[id] ?? (throw StateError('Kernel $id not registered')),
        health = await kernel.healthCheck();
    if (health.status == KernelHealthStatus.unavailable) {
      throw StateError('Kernel $id unavailable: ${health.message}');
    }
    activeId = id;
    return health;
  }

  Future<KernelHealth> selectWithFallback(
    String id, {
    String? fallbackId,
  }) async {
    final previous = activeId;
    try {
      return await select(id);
    } catch (_) {
      final fallback = fallbackId ?? previous;
      if (fallback != null &&
          fallback != id &&
          _kernels.containsKey(fallback)) {
        return select(fallback);
      }
      rethrow;
    }
  }

  Future<void> unload(String id) async {
    final kernel = _kernels.remove(id);
    if (kernel == null) return;
    await kernel.unload();
    if (activeId == id) activeId = null;
  }

  Future<KernelHealth> healthCheck() => active.healthCheck();
  List<KernelDescriptor> get descriptors =>
      _kernels.values.map((e) => e.descriptor).toList();
}
