import '../models/workflow_models.dart';

class WorkflowGraph {
  final Map<String, Set<String>> dependencies = {};
  void build(ReverseWorkflow workflow) {
    for (final step in workflow.steps) {
      dependencies.putIfAbsent(step.id, () => {});
    }
    for (var i = 1; i < workflow.steps.length; i++) {
      dependencies[workflow.steps[i - 1].id]!.add(workflow.steps[i].id);
    }
  }

  Set<String> downstream(String id) {
    final out = <String>{};
    void visit(String n) {
      for (final c in dependencies[n] ?? const <String>{}) {
        if (out.add(c)) visit(c);
      }
    }

    visit(id);
    return out;
  }
}
