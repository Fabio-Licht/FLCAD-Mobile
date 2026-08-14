enum ProfileIssueType {
  openEnd,
  brokenLoop,
  duplicatedEntity,
  overlap,
  microGap,
  crossing,
  invalidOrientation,
  selfIntersection,
  zeroArea,
  tinyRegion,
  nestedError,
  disconnectedIsland,
}

class ProfileIssue {
  const ProfileIssue(
    this.type,
    this.message, {
    this.entityIds = const [],
    this.suggestedFix,
  });
  final ProfileIssueType type;
  final String message;
  final List<String> entityIds;
  final String? suggestedFix;
}

class ProfileValidationResult {
  const ProfileValidationResult(this.issues);
  final List<ProfileIssue> issues;
  bool get valid => issues.isEmpty;
}
