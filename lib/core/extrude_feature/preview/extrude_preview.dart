import '../../cad_kernel/models/kernel_models.dart';
import '../models/extrude_models.dart';

class ExtrudeBoundingBox {
  const ExtrudeBoundingBox(this.width, this.height, this.depth);
  final double width, height, depth;
}

class ExtrudePreview {
  const ExtrudePreview({
    required this.extrudeId,
    required this.predictedVolume,
    required this.boundingBox,
    required this.predictedFaces,
    required this.operation,
    required this.color,
    required this.warnings,
    required this.readiness,
    required this.kernelStatus,
  });
  final String extrudeId, operation, color, kernelStatus;
  final double predictedVolume;
  final ExtrudeBoundingBox boundingBox;
  final int predictedFaces;
  final List<String> warnings;
  final bool readiness;
}

class ExtrudePreviewEngine {
  ExtrudePreview create(
    ExtrudeFeature feature, {
    required double profileArea,
    required double profileWidth,
    required double profileHeight,
    required KernelDescriptor kernel,
  }) {
    final supported = kernel.capabilities.supports(KernelCapability.extrude),
        distance = feature.parameters.distance.abs();
    return ExtrudePreview(
      extrudeId: feature.id,
      predictedVolume: profileArea * distance,
      boundingBox: ExtrudeBoundingBox(profileWidth, profileHeight, distance),
      predictedFaces: feature.input.profileIds.length * 6,
      operation: feature.parameters.type.name,
      color: feature.parameters.type == ExtrudeType.cut ? 'red' : 'blue',
      warnings: [
        if (!supported) 'Kernel does not support Extrude',
        if (profileArea <= 0) 'Profile area is zero',
      ],
      readiness: supported && profileArea > 0,
      kernelStatus: supported ? 'Ready' : 'UnsupportedOperation',
    );
  }
}
