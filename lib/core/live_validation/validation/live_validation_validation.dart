import '../models/validation_models.dart';

enum LiveValidationIssueType {
  missingSource,
  missingTarget,
  sameSourceAndTarget,
  invalidTolerance,
  invalidThresholds,
  missingShape,
  inactiveSession,
}

class LiveValidationIssue {
  const LiveValidationIssue(this.type, this.message);
  final LiveValidationIssueType type;
  final String message;
}

class LiveValidationValidationResult {
  const LiveValidationValidationResult(this.issues);
  final List<LiveValidationIssue> issues;
  bool get valid => issues.isEmpty;
}

class LiveValidationValidator {
  const LiveValidationValidator();
  LiveValidationValidationResult validate(LiveValidationSession session) {
    final issues = <LiveValidationIssue>[];
    if (session.source.id.isEmpty) {
      issues.add(
        const LiveValidationIssue(
          LiveValidationIssueType.missingSource,
          'Missing validation source',
        ),
      );
    }
    if (session.target.id.isEmpty) {
      issues.add(
        const LiveValidationIssue(
          LiveValidationIssueType.missingTarget,
          'Missing validation target',
        ),
      );
    }
    if (session.source.id == session.target.id) {
      issues.add(
        const LiveValidationIssue(
          LiveValidationIssueType.sameSourceAndTarget,
          'Source and target must differ',
        ),
      );
    }
    if (!session.parameters.tolerance.isFinite ||
        session.parameters.tolerance <= 0) {
      issues.add(
        const LiveValidationIssue(
          LiveValidationIssueType.invalidTolerance,
          'Tolerance must be positive',
        ),
      );
    }
    if (session.parameters.warningThreshold < 0 ||
        session.parameters.criticalThreshold <
            session.parameters.warningThreshold) {
      issues.add(
        const LiveValidationIssue(
          LiveValidationIssueType.invalidThresholds,
          'Invalid deviation thresholds',
        ),
      );
    }
    if (session.target.shape == null) {
      issues.add(
        const LiveValidationIssue(
          LiveValidationIssueType.missingShape,
          'Official target ShapeHandle required',
        ),
      );
    }
    return LiveValidationValidationResult(issues);
  }
}
