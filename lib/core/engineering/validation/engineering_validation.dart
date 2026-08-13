enum EngineeringIssueSeverity { info, warning, error, critical }

class EngineeringIssue {
  const EngineeringIssue(
    this.code,
    this.message,
    this.severity, {
    this.entityId,
    this.suggestion,
  });
  final String code, message;
  final EngineeringIssueSeverity severity;
  final String? entityId, suggestion;
}

class EngineeringValidation {
  const EngineeringValidation(this.issues);
  final List<EngineeringIssue> issues;
  bool get valid => !issues.any(
    (i) =>
        i.severity == EngineeringIssueSeverity.error ||
        i.severity == EngineeringIssueSeverity.critical,
  );
  EngineeringValidation merge(EngineeringValidation other) =>
      EngineeringValidation([...issues, ...other.issues]);
}
