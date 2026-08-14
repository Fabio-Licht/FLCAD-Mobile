import '../../cad_kernel/models/kernel_models.dart';
import '../models/reference_models.dart';

enum ReferenceIssueType {
  missingReference,
  invalidIntersection,
  coincidentPlanes,
  degenerateAxis,
  invalidPoint,
  circularDependency,
  kernelUnavailable,
  unsupportedOperation,
}

class ReferenceIssue {
  const ReferenceIssue(this.type, this.message);
  final ReferenceIssueType type;
  final String message;
}

class ReferenceValidationResult {
  const ReferenceValidationResult(this.issues);
  final List<ReferenceIssue> issues;
  bool get valid => issues.isEmpty;
}

class ReferenceValidator {
  const ReferenceValidator();
  ReferenceValidationResult validate(
    ReferenceEntity entity,
    KernelDescriptor kernel, {
    bool kernelHealthy = true,
  }) {
    final issues = <ReferenceIssue>[],
        methodsRequiringInputs = {
          ReferenceMethod.offsetPlane,
          ReferenceMethod.threePoints,
          ReferenceMethod.planeDistance,
          ReferenceMethod.parallelPlane,
          ReferenceMethod.perpendicularPlane,
          ReferenceMethod.midPlane,
          ReferenceMethod.planeFromFace,
          ReferenceMethod.twoPoints,
          ReferenceMethod.cylinderAxis,
          ReferenceMethod.coneAxis,
          ReferenceMethod.planeIntersection,
          ReferenceMethod.edgeAxis,
          ReferenceMethod.axisIntersection,
          ReferenceMethod.curveIntersection,
          ReferenceMethod.meshPick,
          ReferenceMethod.edgeMidpoint,
          ReferenceMethod.planeAxis,
        };
    if (methodsRequiringInputs.contains(entity.method) &&
        entity.input.referenceIds.isEmpty) {
      issues.add(
        const ReferenceIssue(
          ReferenceIssueType.missingReference,
          'Missing reference',
        ),
      );
    }
    if (!entity.parameters.origin.finite) {
      issues.add(
        const ReferenceIssue(ReferenceIssueType.invalidPoint, 'Invalid point'),
      );
    }
    if ({
          ReferenceType.datumAxis,
          ReferenceType.constructionAxis,
        }.contains(entity.type) &&
        (!entity.parameters.direction.finite ||
            entity.parameters.direction.zero)) {
      issues.add(
        const ReferenceIssue(
          ReferenceIssueType.degenerateAxis,
          'Degenerate axis',
        ),
      );
    }
    if ({
          ReferenceMethod.planeIntersection,
          ReferenceMethod.axisIntersection,
          ReferenceMethod.curveIntersection,
        }.contains(entity.method) &&
        entity.input.referenceIds.length < 2) {
      issues.add(
        const ReferenceIssue(
          ReferenceIssueType.invalidIntersection,
          'Invalid intersection',
        ),
      );
    }
    if (!kernelHealthy) {
      issues.add(
        const ReferenceIssue(
          ReferenceIssueType.kernelUnavailable,
          'KernelUnavailable',
        ),
      );
    } else if (!kernel.capabilities.supports(KernelCapability.planeSurface)) {
      issues.add(
        const ReferenceIssue(
          ReferenceIssueType.unsupportedOperation,
          'UnsupportedOperation: REFERENCE_GEOMETRY',
        ),
      );
    }
    return ReferenceValidationResult(issues);
  }
}
