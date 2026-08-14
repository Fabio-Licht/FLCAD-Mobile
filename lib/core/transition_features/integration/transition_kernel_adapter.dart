import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../cad_kernel/transactions/kernel_transaction_manager.dart';
import '../models/transition_models.dart';

class TransitionFeatureKernelAdapter {
  const TransitionFeatureKernelAdapter(this.kernel);
  final GeometryKernelAPI kernel;
  Future<TransitionExecutionResult> execute(
    String projectId,
    TransitionFeature feature,
  ) async {
    final health = await kernel.healthCheck(),
        capability = feature.family == TransitionFamily.sweep
            ? KernelCapability.sweep
            : KernelCapability.loft;
    if (health.status == KernelHealthStatus.unavailable) {
      return TransitionExecutionResult(
        TransitionStatus.kernelUnavailable,
        diagnostics: ['KernelUnavailable: ${health.message}'],
      );
    }
    if (!kernel.descriptor.capabilities.supports(capability)) {
      return TransitionExecutionResult(
        TransitionStatus.unsupportedOperation,
        diagnostics: [
          'UnsupportedOperation: ${feature.family.name.toUpperCase()}',
        ],
      );
    }
    final transactions = KernelTransactionManager(kernel),
        transaction = await transactions.begin(projectId);
    try {
      final shape = await kernel.create(
        feature.family.name.toUpperCase(),
        {
          'profiles': feature.input.kernelProfiles,
          'paths': feature.input.kernelPaths,
          'guides': feature.input.kernelGuides,
          'references': feature.input.referenceIds,
          ...feature.parameters.toJson(),
        },
        persistentId: '${feature.id}:shape',
        expectedType:
            feature.parameters.sweepType == SweepType.surface ||
                feature.parameters.loftType == LoftType.surface
            ? CADShapeType.face
            : CADShapeType.solid,
        transaction: transaction,
      );
      final diagnostics = await kernel.validate(shape, const {
        'self-intersection',
        'non-manifold',
        'invalid-solid',
        'invalid-guide',
        'invalid-sections',
      });
      if (diagnostics.any((e) => e.startsWith('error:'))) {
        await transactions.rollback(transaction.id);
        return TransitionExecutionResult(
          TransitionStatus.failed,
          diagnostics: diagnostics,
        );
      }
      await transactions.commit(transaction.id);
      return TransitionExecutionResult(
        TransitionStatus.success,
        shape: shape,
        diagnostics: diagnostics,
      );
    } catch (error) {
      try {
        await transactions.rollback(transaction.id);
      } catch (_) {}
      return TransitionExecutionResult(
        TransitionStatus.failed,
        diagnostics: ['ExecutionFailure: $error'],
      );
    }
  }
}
