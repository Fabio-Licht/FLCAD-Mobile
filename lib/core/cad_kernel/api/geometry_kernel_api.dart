import '../models/kernel_models.dart';
import '../io/kernel_io_models.dart';

abstract interface class GeometryKernelAPI {
  KernelDescriptor get descriptor;
  Future<KernelHealth> healthCheck();
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  });
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks);
  Future<void> begin(KernelTransaction transaction);
  Future<void> commit(KernelTransaction transaction);
  Future<void> rollback(KernelTransaction transaction);
  Future<void> unload();
}

abstract interface class InterchangeGeometryKernelAPI
    implements GeometryKernelAPI {
  Future<ShapeHandle> importFile(
    String path,
    KernelExchangeFormat format, {
    required String projectId,
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  });
  Future<void> exportFile(
    ShapeHandle handle,
    String path,
    KernelExchangeFormat format, {
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  });
  Future<List<GeometryDiagnostic>> diagnose(ShapeHandle handle);
  Future<List<HealingProposal>> proposeHealing(ShapeHandle handle);
  Future<ShapeHandle> sew(
    List<ShapeHandle> faces, {
    required String projectId,
    required double tolerance,
  });
  Future<KernelMeshResult> mesh(
    ShapeHandle handle, {
    required String outputPath,
    required double deflection,
  });
}

class UnavailableGeometryKernel implements GeometryKernelAPI {
  const UnavailableGeometryKernel();
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'none',
    name: 'No CAD Kernel',
    version: '0.0.0',
    vendor: 'FLCAD',
    capabilities: KernelCapabilities.none,
  );
  @override
  Future<KernelHealth> healthCheck() async => KernelHealth(
    KernelHealthStatus.unavailable,
    'No CAD kernel plugin installed',
    DateTime.now(),
  );
  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) => throw UnsupportedError('CAD kernel operation unavailable: $operation');
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) =>
      throw UnsupportedError(
        'Geometry validation requires a CAD kernel plugin',
      );
  @override
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  @override
  Future<void> unload() async {}
}
