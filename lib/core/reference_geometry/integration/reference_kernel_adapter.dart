import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../cad_kernel/transactions/kernel_transaction_manager.dart';
import '../models/reference_models.dart';

class ReferenceKernelAdapter {
  const ReferenceKernelAdapter(this.kernel);
  final GeometryKernelAPI kernel;
  Future<ReferenceExecutionResult> execute(
    String projectId,
    ReferenceEntity entity,
  ) async {
    final health = await kernel.healthCheck();
    if (health.status == KernelHealthStatus.unavailable) {
      return ReferenceExecutionResult(
        ReferenceStatus.kernelUnavailable,
        diagnostics: ['KernelUnavailable: ${health.message}'],
      );
    }
    if (!kernel.descriptor.capabilities.supports(
      KernelCapability.planeSurface,
    )) {
      return const ReferenceExecutionResult(
        ReferenceStatus.unsupportedOperation,
        diagnostics: ['UnsupportedOperation: REFERENCE_GEOMETRY'],
      );
    }
    final manager = KernelTransactionManager(kernel),
        transaction = await manager.begin(projectId);
    try {
      final shape = await kernel.create(
            'REFERENCE_GEOMETRY',
            {
              'type': entity.type.name,
              'method': entity.method.name,
              'inputs': entity.input.kernelReferences,
              ...entity.parameters.toJson(),
            },
            persistentId: '${entity.id}:shape',
            expectedType: _shapeType(entity.type),
            transaction: transaction,
          ),
          diagnostics = await kernel.validate(shape, const {
            'invalid-reference',
            'degenerate-axis',
            'coincident-plane',
            'invalid-intersection',
          });
      if (diagnostics.any((e) => e.startsWith('error:'))) {
        await manager.rollback(transaction.id);
        return ReferenceExecutionResult(
          ReferenceStatus.failed,
          diagnostics: diagnostics,
        );
      }
      await manager.commit(transaction.id);
      return ReferenceExecutionResult(
        ReferenceStatus.ready,
        shape: shape,
        diagnostics: diagnostics,
      );
    } catch (error) {
      try {
        await manager.rollback(transaction.id);
      } catch (_) {}
      return ReferenceExecutionResult(
        ReferenceStatus.failed,
        diagnostics: ['ExecutionFailure: $error'],
      );
    }
  }

  CADShapeType _shapeType(ReferenceType type) => switch (type) {
    ReferenceType.datumPoint ||
    ReferenceType.constructionPoint => CADShapeType.vertex,
    ReferenceType.datumAxis ||
    ReferenceType.constructionAxis ||
    ReferenceType.referenceCurve => CADShapeType.edge,
    ReferenceType.datumPlane ||
    ReferenceType.constructionPlane => CADShapeType.face,
    _ => CADShapeType.compound,
  };
}
