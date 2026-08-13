import '../dependencies/dependency_graph.dart';
import '../models/reconstruction_models.dart';

class WorkflowValidation {
  const WorkflowValidation(this.valid, this.issues);
  final bool valid;
  final List<String> issues;
}

class ReconstructionWorkflowValidator {
  const ReconstructionWorkflowValidator();
  WorkflowValidation validate(ReconstructionWorkflow workflow) {
    final issues = <String>[];
    try {
      final graph = ReconstructionDependencyGraph(workflow.stages);
      graph.topologicalOrder();
    } catch (e) {
      issues.add(e.toString());
    }
    if (workflow.stages.map((s) => s.id).toSet().length !=
        workflow.stages.length) {
      issues.add('Duplicate stage identifiers');
    }
    for (final stage in workflow.stages) {
      if (stage.decision.confidence < 0 || stage.decision.confidence > 1) {
        issues.add('Invalid confidence for ${stage.id}');
      }
      if (stage.type == ReconstructionStageType.surface &&
          stage.name.toLowerCase().contains('created')) {
        issues.add('Surface stage must plan rather than claim creation');
      }
    }
    return WorkflowValidation(issues.isEmpty, issues);
  }
}
