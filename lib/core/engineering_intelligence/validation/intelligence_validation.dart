import '../models/intelligence_models.dart';

enum IntelligenceIssueType { missingProject, invalidQuality, invalidCounts }

class IntelligenceIssue {
  const IntelligenceIssue(this.type, this.message);
  final IntelligenceIssueType type;
  final String message;
}

class IntelligenceValidationResult {
  const IntelligenceValidationResult(this.issues);
  final List<IntelligenceIssue> issues;
  bool get valid => issues.isEmpty;
}

class IntelligenceValidator {
  const IntelligenceValidator();
  IntelligenceValidationResult validate(ProjectKnowledgeSnapshot snapshot) {
    final issues = <IntelligenceIssue>[];
    if (snapshot.projectId.isEmpty) {
      issues.add(
        const IntelligenceIssue(
          IntelligenceIssueType.missingProject,
          'Project ID is required',
        ),
      );
    }
    final qualities = [
      snapshot.averageFeatureQuality,
      snapshot.averageReferenceQuality,
      snapshot.averageAlignmentQuality,
      snapshot.averageValidationQuality,
    ];
    if (qualities.any((e) => !e.isFinite || e < 0 || e > 100)) {
      issues.add(
        const IntelligenceIssue(
          IntelligenceIssueType.invalidQuality,
          'Quality values must be between 0 and 100',
        ),
      );
    }
    if ([
      snapshot.features,
      snapshot.references,
      snapshot.alignments,
      snapshot.validations,
    ].any((e) => e < 0)) {
      issues.add(
        const IntelligenceIssue(
          IntelligenceIssueType.invalidCounts,
          'Project counts cannot be negative',
        ),
      );
    }
    return IntelligenceValidationResult(issues);
  }
}
