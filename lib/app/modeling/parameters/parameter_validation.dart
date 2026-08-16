class ParameterIssue {
  const ParameterIssue(this.field, this.message);
  final String field, message;
}

class ParameterValidation {
  const ParameterValidation();
  List<ParameterIssue> validate(Map<String, Object?> values) {
    final issues = <ParameterIssue>[];
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null || value is String && value.trim().isEmpty) {
        issues.add(ParameterIssue(entry.key, 'A value is required.'));
      }
      if (value is double && (!value.isFinite || value < 0)) {
        issues.add(
          ParameterIssue(entry.key, 'Use a finite non-negative value.'),
        );
      }
    }
    return issues;
  }
}
