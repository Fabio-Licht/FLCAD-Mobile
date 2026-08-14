import '../../cad_kernel/models/kernel_models.dart';
import '../../profile_recognition/models/profile_models.dart';
import '../models/revolve_models.dart';
import '../parameters/revolve_axis_engine.dart';

enum RevolveValidationIssueType {
  openProfile,
  missingAxis,
  invalidAxis,
  axisCrossingProfile,
  invalidAngle,
  zeroAngle,
  angleOver360,
  missingReference,
  kernelUnavailable,
  unsupportedCapability,
  circularDependency,
  invalidParameter,
}

class RevolveValidationIssue {
  const RevolveValidationIssue(this.type, this.message, {this.suggestedFix});
  final RevolveValidationIssueType type;
  final String message;
  final String? suggestedFix;
}

class RevolveValidationResult {
  const RevolveValidationResult(this.issues);
  final List<RevolveValidationIssue> issues;
  bool get valid => issues.isEmpty;
}

class RevolveValidator {
  const RevolveValidator();
  RevolveValidationResult validate(
    RevolveFeature f,
    Iterable<RecognizedProfile> profiles,
    KernelDescriptor kernel, {
    bool kernelHealthy = true,
  }) {
    final issues = <RevolveValidationIssue>[],
        selected = profiles
            .where((p) => f.input.profileIds.contains(p.id))
            .toList(),
        axis = const RevolveAxisEngine().analyze(f.input.axis);
    if (selected.any(
          (p) => p.type == ProfileType.open || p.type == ProfileType.chain,
        ) &&
        f.parameters.type != RevolveType.surface) {
      issues.add(
        const RevolveValidationIssue(
          RevolveValidationIssueType.openProfile,
          'Solid revolve requires a closed profile',
        ),
      );
    }
    if (!axis.valid) {
      for (final d in axis.diagnostics) {
        issues.add(
          RevolveValidationIssue(
            d.type == AxisDiagnosticType.missing
                ? RevolveValidationIssueType.missingAxis
                : RevolveValidationIssueType.invalidAxis,
            d.message,
          ),
        );
      }
    }
    if (f.parameters.angle == 0) {
      issues.add(
        const RevolveValidationIssue(
          RevolveValidationIssueType.zeroAngle,
          'Revolve angle cannot be zero',
        ),
      );
    }
    if (f.parameters.angle.abs() > 360) {
      issues.add(
        const RevolveValidationIssue(
          RevolveValidationIssueType.angleOver360,
          'Revolve angle cannot exceed 360 degrees',
        ),
      );
    }
    if (f.parameters.angle.isNaN) {
      issues.add(
        const RevolveValidationIssue(
          RevolveValidationIssueType.invalidAngle,
          'Invalid angle',
        ),
      );
    }
    if (selected.isEmpty || f.input.kernelProfile == null) {
      issues.add(
        const RevolveValidationIssue(
          RevolveValidationIssueType.missingReference,
          'Recognized profile and official ShapeHandle are required',
        ),
      );
    }
    if (!kernelHealthy) {
      issues.add(
        const RevolveValidationIssue(
          RevolveValidationIssueType.kernelUnavailable,
          'KernelUnavailable',
        ),
      );
    } else if (!kernel.capabilities.supports(KernelCapability.revolve)) {
      issues.add(
        const RevolveValidationIssue(
          RevolveValidationIssueType.unsupportedCapability,
          'UnsupportedOperation: REVOLVE',
        ),
      );
    }
    return RevolveValidationResult(issues);
  }
}
