enum FeatureValidationIssueType {
  missingInput,
  invalidReference,
  suppressedParent,
  circularDependency,
  invalidParameter,
  executionFailure,
  kernelUnavailable,
  unsupportedFeature,
  brokenDependency,
}

class FeatureValidationIssue {
  const FeatureValidationIssue(
    this.type,
    this.message, {
    this.featureId,
    this.suggestedFix,
  });
  final FeatureValidationIssueType type;
  final String message;
  final String? featureId, suggestedFix;
}

class FeatureValidationResult {
  const FeatureValidationResult(this.issues);
  final List<FeatureValidationIssue> issues;
  bool get valid => issues.isEmpty;
}
