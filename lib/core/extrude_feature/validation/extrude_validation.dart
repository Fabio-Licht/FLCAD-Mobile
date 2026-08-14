import '../../cad_kernel/models/kernel_models.dart';
import '../../profile_recognition/models/profile_models.dart';
import '../models/extrude_models.dart';

enum ExtrudeValidationIssueType {
  openProfile,
  zeroArea,
  multipleDisconnectedRegions,
  invalidReference,
  missingDirection,
  missingDistance,
  kernelUnavailable,
  suppressedParent,
  circularDependency,
  unsupportedKernelCapability,
}

class ExtrudeValidationIssue {
  const ExtrudeValidationIssue(this.type, this.message, {this.suggestedFix});
  final ExtrudeValidationIssueType type;
  final String message;
  final String? suggestedFix;
}

class ExtrudeValidationResult {
  const ExtrudeValidationResult(this.issues);
  final List<ExtrudeValidationIssue> issues;
  bool get valid => issues.isEmpty;
}

class ExtrudeValidator {
  const ExtrudeValidator();
  ExtrudeValidationResult validate(
    ExtrudeFeature feature,
    Iterable<RecognizedProfile> profiles,
    KernelDescriptor kernel, {
    bool kernelHealthy = true,
  }) {
    final issues = <ExtrudeValidationIssue>[];
    final selected = profiles
        .where((p) => feature.input.profileIds.contains(p.id))
        .toList();
    if (selected.any(
      (p) => p.type == ProfileType.open || p.type == ProfileType.chain,
    )) {
      issues.add(
        const ExtrudeValidationIssue(
          ExtrudeValidationIssueType.openProfile,
          'Solid extrude requires a closed profile',
          suggestedFix: 'Close the profile or use Surface Extrude',
        ),
      );
    }
    if (selected.any((p) => p.area <= 0) &&
        feature.parameters.type != ExtrudeType.surface) {
      issues.add(
        const ExtrudeValidationIssue(
          ExtrudeValidationIssueType.zeroArea,
          'Profile area must be positive',
        ),
      );
    }
    if (selected.isEmpty) {
      issues.add(
        const ExtrudeValidationIssue(
          ExtrudeValidationIssueType.invalidReference,
          'No recognized profile selected',
        ),
      );
    }
    if (feature.parameters.direction.x == 0 &&
        feature.parameters.direction.y == 0 &&
        feature.parameters.direction.z == 0) {
      issues.add(
        const ExtrudeValidationIssue(
          ExtrudeValidationIssueType.missingDirection,
          'Extrude direction is required',
        ),
      );
    }
    if (feature.parameters.distance <= 0 &&
        feature.parameters.type == ExtrudeType.blind) {
      issues.add(
        const ExtrudeValidationIssue(
          ExtrudeValidationIssueType.missingDistance,
          'Positive distance is required',
        ),
      );
    }
    if (!kernelHealthy) {
      issues.add(
        const ExtrudeValidationIssue(
          ExtrudeValidationIssueType.kernelUnavailable,
          'KernelUnavailable',
        ),
      );
    } else if (!kernel.capabilities.supports(KernelCapability.extrude)) {
      issues.add(
        const ExtrudeValidationIssue(
          ExtrudeValidationIssueType.unsupportedKernelCapability,
          'UnsupportedOperation: EXTRUDE',
        ),
      );
    }
    if (feature.input.kernelProfile == null) {
      issues.add(
        const ExtrudeValidationIssue(
          ExtrudeValidationIssueType.invalidReference,
          'Official kernel profile ShapeHandle is required',
        ),
      );
    }
    return ExtrudeValidationResult(issues);
  }
}
