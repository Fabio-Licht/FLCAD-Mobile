import '../../engineering_studio/models/studio_models.dart';
import '../manager/kernel_manager.dart';
import '../models/kernel_models.dart';

class KernelStatusSnapshot {
  const KernelStatusSnapshot({
    required this.kernel,
    required this.kernelId,
    required this.version,
    required this.status,
    required this.capabilities,
    required this.loaded,
    required this.backend,
    this.memoryBytes = 0,
    this.diagnostics = const {},
  });
  final String kernel, kernelId, version, status, backend;
  final Set<KernelCapability> capabilities;
  final bool loaded;
  final int memoryBytes;
  final Map<String, dynamic> diagnostics;

  EngineeringTreeNode toTreeNode(String projectId) => EngineeringTreeNode(
    id: 'kernel-status-$projectId',
    projectId: projectId,
    name: kernel,
    type: StudioEntityType.kernelStatus,
    status: status,
    context: {
      'kernelId': kernelId,
      'kernelVersion': version,
      'kernelCapabilities': capabilities.map((e) => e.name).toList(),
      'loaded': loaded,
      'backend': backend,
      'memoryBytes': memoryBytes,
      'nativeDiagnostics': diagnostics,
    },
  );
}

class OpenCascadeStudioIntegration {
  const OpenCascadeStudioIntegration();
  Future<KernelStatusSnapshot> inspect(KernelManager manager) async {
    final kernel = manager.active;
    final descriptor = kernel.descriptor;
    if (descriptor.version == 'uninitialized') {
      return KernelStatusSnapshot(
        kernel: descriptor.name,
        kernelId: descriptor.id,
        version: descriptor.version,
        status: 'uninitialized',
        capabilities: descriptor.capabilities.values,
        loaded: false,
        backend: descriptor.vendor,
        diagnostics: const {
          'message': 'Kernel registered; lazy loading pending',
        },
      );
    }
    final health = await kernel.healthCheck();
    return KernelStatusSnapshot(
      kernel: descriptor.name,
      kernelId: descriptor.id,
      version: descriptor.version,
      status: health.status.name,
      capabilities: descriptor.capabilities.values,
      loaded: descriptor.id != 'none',
      backend: descriptor.vendor,
      diagnostics: {
        'message': health.message,
        'checkedAt': health.checkedAt.toIso8601String(),
      },
    );
  }
}
