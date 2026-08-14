import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../cad_kernel/transactions/kernel_transaction_manager.dart';
import '../models/alignment_models.dart';

class AlignmentKernelAdapter {
  const AlignmentKernelAdapter(this.kernel);
  final GeometryKernelAPI kernel;
  Future<AlignmentExecutionResult> commit(
    String projectId,
    Alignment alignment,
  ) async {
    final health = await kernel.healthCheck();
    if (health.status == KernelHealthStatus.unavailable) {
      return AlignmentExecutionResult(
        AlignmentStatus.kernelUnavailable,
        diagnostics: ['KernelUnavailable: ${health.message}'],
      );
    }
    if (!kernel.descriptor.capabilities.supports(KernelCapability.brep)) {
      return const AlignmentExecutionResult(
        AlignmentStatus.unsupportedOperation,
        diagnostics: ['UnsupportedOperation: ALIGNMENT_TRANSFORM'],
      );
    }
    final moving = alignment.input.movingShape;
    if (moving == null) {
      return const AlignmentExecutionResult(
        AlignmentStatus.invalid,
        diagnostics: ['Official moving ShapeHandle required'],
      );
    }
    final manager = KernelTransactionManager(kernel),
        transaction = await manager.begin(projectId);
    try {
      final shape = await kernel.create(
            'ALIGNMENT_TRANSFORM',
            {
              'movingShape': moving,
              'fixedShape': alignment.input.fixedShape,
              'type': alignment.type.name,
              ...alignment.parameters.toJson(),
            },
            persistentId: '${alignment.id}:aligned',
            expectedType: moving.type,
            transaction: transaction,
          ),
          diagnostics = await kernel.validate(shape, const {
            'invalid-transform',
            'singular-matrix',
            'invalid-topology',
          });
      if (diagnostics.any((e) => e.startsWith('error:'))) {
        await manager.rollback(transaction.id);
        return AlignmentExecutionResult(
          AlignmentStatus.failed,
          diagnostics: diagnostics,
        );
      }
      await manager.commit(transaction.id);
      return AlignmentExecutionResult(
        AlignmentStatus.committed,
        shape: shape,
        diagnostics: diagnostics,
      );
    } catch (error) {
      try {
        await manager.rollback(transaction.id);
      } catch (_) {}
      return AlignmentExecutionResult(
        AlignmentStatus.failed,
        diagnostics: ['ExecutionFailure: $error'],
      );
    }
  }
}
