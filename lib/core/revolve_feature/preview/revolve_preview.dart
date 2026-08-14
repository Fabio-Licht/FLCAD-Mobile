import 'dart:math' as math;
import '../../cad_kernel/models/kernel_models.dart';
import '../models/revolve_models.dart';
import '../parameters/revolve_axis_engine.dart';

class RevolveBoundingBox {
  const RevolveBoundingBox(this.width, this.height, this.depth);
  final double width, height, depth;
}

class RevolvePreview {
  const RevolvePreview({
    required this.revolveId,
    required this.predictedVolume,
    required this.boundingBox,
    required this.predictedFaces,
    required this.angle,
    required this.axis,
    required this.direction,
    required this.warnings,
    required this.readiness,
    required this.kernelStatus,
  });
  final String revolveId, direction, kernelStatus;
  final double predictedVolume, angle;
  final RevolveBoundingBox boundingBox;
  final int predictedFaces;
  final RevolveAxis axis;
  final List<String> warnings;
  final bool readiness;
}

class RevolvePreviewEngine {
  RevolvePreview create(
    RevolveFeature f, {
    required double profileArea,
    required double centroidRadius,
    required KernelDescriptor kernel,
  }) {
    final analysis = const RevolveAxisEngine().analyze(f.input.axis),
        supported = kernel.capabilities.supports(KernelCapability.revolve),
        fraction = f.parameters.angle.abs() / 360,
        diameter = centroidRadius * 2;
    return RevolvePreview(
      revolveId: f.id,
      predictedVolume: profileArea * 2 * math.pi * centroidRadius * fraction,
      boundingBox: RevolveBoundingBox(
        diameter,
        diameter,
        math.sqrt(profileArea.abs()),
      ),
      predictedFaces: f.input.profileIds.length * 4,
      angle: f.parameters.angle,
      axis: f.input.axis,
      direction: f.parameters.reverse ? 'reverse' : 'forward',
      warnings: [
        if (!analysis.valid) ...analysis.diagnostics.map((d) => d.message),
        if (!supported) 'Kernel does not support Revolve',
      ],
      readiness: analysis.valid && supported && profileArea > 0,
      kernelStatus: supported ? 'Ready' : 'UnsupportedOperation',
    );
  }
}
