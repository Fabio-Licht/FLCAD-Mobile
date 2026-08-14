import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../cad_kernel/transactions/kernel_transaction_manager.dart';
import '../models/revolve_models.dart';

class RevolveFeatureKernelAdapter {
  const RevolveFeatureKernelAdapter(this.kernel);
  final GeometryKernelAPI kernel;
  Future<RevolveExecutionResult> execute(
    String projectId,
    RevolveFeature f,
  ) async {
    final health = await kernel.healthCheck();
    if (health.status == KernelHealthStatus.unavailable) {
      return RevolveExecutionResult(
        RevolveStatus.kernelUnavailable,
        diagnostics: ['KernelUnavailable: ${health.message}'],
      );
    }
    if (!kernel.descriptor.capabilities.supports(KernelCapability.revolve)) {
      return RevolveExecutionResult(
        RevolveStatus.unsupportedOperation,
        diagnostics: ['UnsupportedOperation: REVOLVE'],
      );
    }
    final input = f.input.kernelProfile;
    if (input == null) {
      return const RevolveExecutionResult(
        RevolveStatus.invalid,
        diagnostics: ['Official kernel profile ShapeHandle is required'],
      );
    }
    final transactions = KernelTransactionManager(kernel),
        transaction = await transactions.begin(projectId);
    try {
      final shape = await kernel.create(
        'REVOLVE',
        {
          'inputs': [input],
          'axis': f.input.axis.toJson(),
          ...f.parameters.toJson(),
        },
        persistentId: '${f.id}:shape',
        expectedType: f.parameters.type == RevolveType.surface
            ? CADShapeType.face
            : CADShapeType.solid,
        transaction: transaction,
      );
      final diagnostics = await kernel.validate(shape, const {
        'open-wire',
        'self-intersection',
        'non-manifold',
        'invalid-solid',
        'axis-crossing',
      });
      if (diagnostics.any((d) => d.startsWith('error:'))) {
        await transactions.rollback(transaction.id);
        return RevolveExecutionResult(
          RevolveStatus.failed,
          diagnostics: diagnostics,
        );
      }
      await transactions.commit(transaction.id);
      return RevolveExecutionResult(
        RevolveStatus.success,
        shape: shape,
        diagnostics: diagnostics,
      );
    } catch (error) {
      try {
        await transactions.rollback(transaction.id);
      } catch (_) {}
      return RevolveExecutionResult(
        RevolveStatus.failed,
        diagnostics: ['ExecutionFailure: $error'],
      );
    }
  }
}
