import '../models/sketch.dart';

class SketchValidationIssue {
  const SketchValidationIssue(this.code, this.message, {this.entityId});
  final String code, message;
  final String? entityId;
}

class SketchValidator {
  const SketchValidator();
  List<SketchValidationIssue> validate(IntelligentSketch sketch) {
    final issues = <SketchValidationIssue>[];
    if (sketch.contexts.isEmpty) {
      issues.add(
        const SketchValidationIssue(
          'missing-context',
          'Sketch requires at least one geometry context',
        ),
      );
    }
    final contexts = sketch.contexts.map((e) => e.id).toSet(), ids = <String>{};
    for (final entity in sketch.entities) {
      if (!ids.add(entity.id)) {
        issues.add(
          SketchValidationIssue(
            'duplicate-entity',
            'Duplicate entity id',
            entityId: entity.id,
          ),
        );
      }
      for (final anchor in entity.anchors) {
        if (!contexts.contains(anchor.contextId) &&
            anchor.contextId != 'active') {
          issues.add(
            SketchValidationIssue(
              'unknown-context',
              'Anchor references an unknown context',
              entityId: entity.id,
            ),
          );
        }
      }
    }
    return issues;
  }
}
