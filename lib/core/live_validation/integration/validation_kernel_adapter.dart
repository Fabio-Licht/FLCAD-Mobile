import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../models/validation_models.dart';

class ValidationKernelAdapter {
  const ValidationKernelAdapter(this.kernel);
  final GeometryKernelAPI kernel;
  Future<ValidationExecutionResult> validate(
    LiveValidationSession session,
    Set<String> regionIds,
  ) async {
    final health = await kernel.healthCheck();
    if (health.status == KernelHealthStatus.unavailable) {
      return ValidationExecutionResult(
        LiveValidationStatus.kernelUnavailable,
        diagnostics: ['KernelUnavailable: ${health.message}'],
      );
    }
    if (!kernel.descriptor.capabilities.supports(KernelCapability.meshing)) {
      return const ValidationExecutionResult(
        LiveValidationStatus.unsupportedOperation,
        diagnostics: ['UnsupportedOperation: LIVE_VALIDATION'],
      );
    }
    final shape = session.target.shape;
    if (shape == null) {
      return const ValidationExecutionResult(
        LiveValidationStatus.invalid,
        diagnostics: ['Official target ShapeHandle required'],
      );
    }
    try {
      final diagnostics = await kernel.validate(shape, {
            'live-validation',
            'source:${session.source.id}',
            for (final region in regionIds) 'region:$region',
          }),
          values = <String, double>{},
          samples = <DeviationSample>[];
      for (final diagnostic in diagnostics) {
        if (diagnostic.startsWith('metric:')) {
          final parts = diagnostic.substring(7).split('=');
          if (parts.length == 2) {
            values[parts[0]] = double.tryParse(parts[1]) ?? double.nan;
          }
        } else if (diagnostic.startsWith('sample:')) {
          final parts = diagnostic.substring(7).split(',');
          if (parts.length == 3) {
            samples.add(
              DeviationSample(
                regionId: parts[0],
                deviation: double.parse(parts[1]),
                confidence: double.parse(parts[2]),
              ),
            );
          }
        }
      }
      final required = {
        'max',
        'average',
        'rms',
        'stddev',
        'within',
        'outside',
        'critical',
        'confidence',
        'stability',
        'quality',
      };
      if (!required.every(values.containsKey) ||
          values.values.any((e) => !e.isFinite)) {
        return ValidationExecutionResult(
          LiveValidationStatus.unsupportedOperation,
          diagnostics: [
            ...diagnostics,
            'UnsupportedOperation: backend did not return deviation metrics',
          ],
        );
      }
      return ValidationExecutionResult(
        LiveValidationStatus.ready,
        metrics: ValidationMetrics(
          maximumDeviation: values['max']!,
          averageDeviation: values['average']!,
          rms: values['rms']!,
          standardDeviation: values['stddev']!,
          withinTolerancePercent: values['within']!,
          outsideTolerancePercent: values['outside']!,
          criticalAreaPercent: values['critical']!,
          confidence: values['confidence']!,
          stability: values['stability']!,
          overallQuality: values['quality']!,
        ),
        samples: samples,
        diagnostics: diagnostics,
      );
    } catch (error) {
      return ValidationExecutionResult(
        LiveValidationStatus.failed,
        diagnostics: ['ValidationFailure: $error'],
      );
    }
  }
}
