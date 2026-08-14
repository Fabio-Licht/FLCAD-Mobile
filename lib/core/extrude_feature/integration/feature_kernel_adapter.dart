import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../cad_kernel/transactions/kernel_transaction_manager.dart';
import '../../feature_modeling/engine/feature_engine.dart';
import '../../feature_modeling/models/feature_models.dart' as platform;
import '../models/extrude_models.dart';

class ExtrudeFeatureKernelAdapter {
  const ExtrudeFeatureKernelAdapter(this.kernel);
  final GeometryKernelAPI kernel;
  Future<ExtrudeExecutionResult> execute(
    String projectId,
    ExtrudeFeature feature,
  ) async {
    final health = await kernel.healthCheck();
    if (health.status == KernelHealthStatus.unavailable) {
      return ExtrudeExecutionResult(
        ExtrudeStatus.kernelUnavailable,
        diagnostics: ['KernelUnavailable: ${health.message}'],
      );
    }
    if (!kernel.descriptor.capabilities.supports(KernelCapability.extrude)) {
      return ExtrudeExecutionResult(
        ExtrudeStatus.unsupportedOperation,
        diagnostics: ['UnsupportedOperation: EXTRUDE'],
      );
    }
    final input = feature.input.kernelProfile;
    if (input == null) {
      return const ExtrudeExecutionResult(
        ExtrudeStatus.invalid,
        diagnostics: ['Official kernel profile ShapeHandle is required'],
      );
    }
    final transactions = KernelTransactionManager(kernel),
        transaction = await transactions.begin(projectId);
    try {
      final shape = await kernel.create(
        'EXTRUDE',
        {
          'inputs': [input],
          ...feature.parameters.toJson(),
        },
        persistentId: '${feature.id}:shape',
        expectedType: feature.parameters.type == ExtrudeType.surface
            ? CADShapeType.face
            : CADShapeType.solid,
        transaction: transaction,
      );
      final diagnostics = await kernel.validate(shape, const {
        'open-wire',
        'self-intersection',
        'non-manifold',
        'invalid-solid',
        'tiny-edges',
      });
      if (diagnostics.any((d) => d.startsWith('error:'))) {
        await transactions.rollback(transaction.id);
        return ExtrudeExecutionResult(
          ExtrudeStatus.failed,
          diagnostics: diagnostics,
        );
      }
      await transactions.commit(transaction.id);
      return ExtrudeExecutionResult(
        ExtrudeStatus.success,
        shape: shape,
        diagnostics: diagnostics,
      );
    } catch (error) {
      try {
        await transactions.rollback(transaction.id);
      } catch (_) {}
      return ExtrudeExecutionResult(
        ExtrudeStatus.failed,
        diagnostics: ['ExecutionFailure: $error'],
      );
    }
  }
}

class FeatureKernelAdapter implements FeatureExecutor {
  FeatureKernelAdapter(this.projectId, this.kernel, this.extrudes);
  final String projectId;
  final GeometryKernelAPI kernel;
  final Map<String, ExtrudeFeature> extrudes;
  @override
  Future<platform.FeatureResult> execute(
    platform.FeatureInstance feature,
    platform.FeatureContext context,
  ) async {
    if (feature.definition.type != platform.FeatureType.extrude) {
      return platform.FeatureResult(
        success: false,
        state: platform.FeatureExecutionState.unsupported,
        diagnostics: ['Unsupported feature: ${feature.definition.type.name}'],
      );
    }
    final extrude = extrudes[feature.id];
    if (extrude == null) {
      return const platform.FeatureResult(
        success: false,
        state: platform.FeatureExecutionState.failed,
        diagnostics: ['Extrude definition not registered'],
      );
    }
    final result = await ExtrudeFeatureKernelAdapter(
      kernel,
    ).execute(projectId, extrude);
    return platform.FeatureResult(
      success: result.success,
      state: switch (result.status) {
        ExtrudeStatus.success => platform.FeatureExecutionState.ready,
        ExtrudeStatus.kernelUnavailable =>
          platform.FeatureExecutionState.kernelUnavailable,
        ExtrudeStatus.unsupportedOperation =>
          platform.FeatureExecutionState.unsupported,
        _ => platform.FeatureExecutionState.failed,
      },
      diagnostics: result.diagnostics,
      outputs: [
        if (result.shape != null)
          platform.FeatureOutput('shape', handle: result.shape),
      ],
    );
  }
}
