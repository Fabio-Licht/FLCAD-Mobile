import '../../cad_kernel/models/kernel_models.dart';
import '../models/transition_models.dart';

class TransitionBounds {
  const TransitionBounds(this.width, this.height, this.depth);
  final double width, height, depth;
}

class TransitionPreview {
  const TransitionPreview({
    required this.featureId,
    required this.bounds,
    required this.predictedFaces,
    required this.sections,
    required this.paths,
    required this.guides,
    required this.operation,
    required this.readiness,
    required this.kernelStatus,
    required this.warnings,
    required this.complexityScore,
  });
  final String featureId, operation, kernelStatus;
  final TransitionBounds bounds;
  final int predictedFaces, sections, paths, guides;
  final bool readiness;
  final List<String> warnings;
  final double complexityScore;
}

class TransitionPreviewEngine {
  const TransitionPreviewEngine();
  TransitionPreview create(TransitionFeature f, KernelDescriptor kernel) {
    final capability = f.family == TransitionFamily.sweep
        ? KernelCapability.sweep
        : KernelCapability.loft;
    final supported = kernel.capabilities.supports(capability),
        sections = f.input.sectionIds.length + f.input.profileIds.length,
        paths = f.input.pathIds.length,
        guides = f.input.guideIds.length,
        complexity = (sections * 12 + paths * 18 + guides * 22)
            .clamp(0, 100)
            .toDouble();
    return TransitionPreview(
      featureId: f.id,
      bounds: TransitionBounds(
        sections.toDouble(),
        (paths + 1).toDouble(),
        (guides + 1).toDouble(),
      ),
      predictedFaces: sections * 4 + guides * 2,
      sections: sections,
      paths: paths,
      guides: guides,
      operation: f.family.name.toUpperCase(),
      readiness:
          supported &&
          sections > 0 &&
          (f.family == TransitionFamily.loft || paths > 0),
      kernelStatus: supported ? 'Ready' : 'UnsupportedOperation',
      warnings: [
        if (!supported) 'Kernel does not support ${f.family.name}',
        if (sections == 0) 'Missing profile or section',
        if (f.family == TransitionFamily.sweep && paths == 0) 'Missing path',
      ],
      complexityScore: complexity,
    );
  }
}
