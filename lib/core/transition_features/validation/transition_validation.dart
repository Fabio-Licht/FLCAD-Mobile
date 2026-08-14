import '../../cad_kernel/models/kernel_models.dart';
import '../../profile_recognition/models/profile_models.dart';
import '../models/transition_models.dart';

enum TransitionIssueType {
  missingProfile,
  missingPath,
  missingSection,
  missingGuide,
  invalidGuide,
  invalidSections,
  openProfile,
  zeroLengthPath,
  selfIntersection,
  circularDependency,
  kernelUnavailable,
  unsupportedCapability,
  missingShapeHandle,
}

class TransitionIssue {
  const TransitionIssue(this.type, this.message);
  final TransitionIssueType type;
  final String message;
}

class TransitionValidationResult {
  const TransitionValidationResult(this.issues);
  final List<TransitionIssue> issues;
  bool get valid => issues.isEmpty;
}

class TransitionValidator {
  const TransitionValidator();
  TransitionValidationResult validate(
    TransitionFeature f,
    Iterable<RecognizedProfile> profiles,
    KernelDescriptor kernel, {
    bool kernelHealthy = true,
  }) {
    final issues = <TransitionIssue>[],
        selected = profiles
            .where((p) => f.input.profileIds.contains(p.id))
            .toList();
    if (f.input.profileIds.isEmpty || selected.isEmpty) {
      issues.add(
        const TransitionIssue(
          TransitionIssueType.missingProfile,
          'Missing Profile',
        ),
      );
    }
    if (f.family == TransitionFamily.sweep && f.input.pathIds.isEmpty) {
      issues.add(
        const TransitionIssue(TransitionIssueType.missingPath, 'Missing Path'),
      );
    }
    if (f.family == TransitionFamily.loft &&
        f.input.profileIds.length + f.input.sectionIds.length < 2) {
      issues.add(
        const TransitionIssue(
          TransitionIssueType.missingSection,
          'Loft requires at least two sections',
        ),
      );
    }
    if (selected.any((p) => p.type == ProfileType.open) &&
        f.parameters.sweepType != SweepType.surface &&
        f.parameters.loftType != LoftType.surface) {
      issues.add(
        const TransitionIssue(
          TransitionIssueType.openProfile,
          'Open profile requires a surface transition',
        ),
      );
    }
    if (f.input.kernelProfiles.isEmpty) {
      issues.add(
        const TransitionIssue(
          TransitionIssueType.missingShapeHandle,
          'Official profile ShapeHandle required',
        ),
      );
    }
    if (f.family == TransitionFamily.sweep && f.input.kernelPaths.isEmpty) {
      issues.add(
        const TransitionIssue(
          TransitionIssueType.zeroLengthPath,
          'Official non-zero path ShapeHandle required',
        ),
      );
    }
    if (f.input.guideIds.isNotEmpty &&
        f.input.kernelGuides.length != f.input.guideIds.length) {
      issues.add(
        const TransitionIssue(
          TransitionIssueType.invalidGuide,
          'Invalid Guide',
        ),
      );
    }
    final capability = f.family == TransitionFamily.sweep
        ? KernelCapability.sweep
        : KernelCapability.loft;
    if (!kernelHealthy) {
      issues.add(
        const TransitionIssue(
          TransitionIssueType.kernelUnavailable,
          'KernelUnavailable',
        ),
      );
    } else if (!kernel.capabilities.supports(capability)) {
      issues.add(
        TransitionIssue(
          TransitionIssueType.unsupportedCapability,
          'UnsupportedOperation: ${f.family.name.toUpperCase()}',
        ),
      );
    }
    return TransitionValidationResult(issues);
  }
}
