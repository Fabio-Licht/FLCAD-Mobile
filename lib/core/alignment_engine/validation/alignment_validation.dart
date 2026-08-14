import '../../cad_kernel/models/kernel_models.dart';
import '../models/alignment_models.dart';

enum AlignmentIssueType {
  missingReferences,
  invalidReference,
  coincidentReferences,
  overConstrained,
  underConstrained,
  singularMatrix,
  impossibleRotation,
  circularDependency,
  kernelUnavailable,
  unsupportedOperation,
  missingShape,
}

class AlignmentIssue {
  const AlignmentIssue(this.type, this.message);
  final AlignmentIssueType type;
  final String message;
}

class AlignmentValidationResult {
  const AlignmentValidationResult(this.issues);
  final List<AlignmentIssue> issues;
  bool get valid => issues.isEmpty;
}

class AlignmentValidator {
  const AlignmentValidator();
  AlignmentValidationResult validate(
    Alignment alignment,
    KernelDescriptor kernel, {
    bool kernelHealthy = true,
  }) {
    final issues = <AlignmentIssue>[],
        moving = alignment.input.movingReferences,
        fixed = alignment.input.fixedReferences;
    if (moving.isEmpty || fixed.isEmpty) {
      issues.add(
        const AlignmentIssue(
          AlignmentIssueType.missingReferences,
          'Missing References',
        ),
      );
    }
    if (moving.any((m) => fixed.any((f) => f.id == m.id))) {
      issues.add(
        const AlignmentIssue(
          AlignmentIssueType.coincidentReferences,
          'Coincident References',
        ),
      );
    }
    if (moving.length != fixed.length) {
      issues.add(
        const AlignmentIssue(
          AlignmentIssueType.invalidReference,
          'Reference mapping count mismatch',
        ),
      );
    }
    if (alignment.type == AlignmentType.threePoint && moving.length < 3) {
      issues.add(
        const AlignmentIssue(
          AlignmentIssueType.underConstrained,
          'Three-point alignment requires three pairs',
        ),
      );
    }
    if (alignment.parameters.lockedAxes.length > 6) {
      issues.add(
        const AlignmentIssue(
          AlignmentIssueType.overConstrained,
          'Over-Constrained Alignment',
        ),
      );
    }
    if (!alignment.parameters.matrix.valid ||
        alignment.parameters.matrix.determinant3.abs() < 1e-12) {
      issues.add(
        const AlignmentIssue(
          AlignmentIssueType.singularMatrix,
          'Singular Matrix',
        ),
      );
    }
    if (!alignment.parameters.rotation.finite) {
      issues.add(
        const AlignmentIssue(
          AlignmentIssueType.impossibleRotation,
          'Impossible Rotation',
        ),
      );
    }
    if (alignment.input.movingShape == null) {
      issues.add(
        const AlignmentIssue(
          AlignmentIssueType.missingShape,
          'Official moving ShapeHandle required',
        ),
      );
    }
    if (!kernelHealthy) {
      issues.add(
        const AlignmentIssue(
          AlignmentIssueType.kernelUnavailable,
          'KernelUnavailable',
        ),
      );
    } else if (!kernel.capabilities.supports(KernelCapability.brep)) {
      issues.add(
        const AlignmentIssue(
          AlignmentIssueType.unsupportedOperation,
          'UnsupportedOperation: ALIGNMENT_TRANSFORM',
        ),
      );
    }
    return AlignmentValidationResult(issues);
  }
}
