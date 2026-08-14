import '../advisor/workflow_advisor.dart';
import '../engine/reverse_workflow_engine.dart';
import '../models/workflow_models.dart';
import '../workflow/reverse_checklist.dart';

class ReverseWorkflowApi {
  const ReverseWorkflowApi(this.engine);
  final ReverseWorkflowEngine engine;
  List<ReverseWorkflow> get workflows =>
      List.unmodifiable(engine.workflows.values);
  ReverseWorkflow create(String projectId, String name) =>
      engine.create(projectId, name);
  ReverseWorkflow open(String id) => engine.open(id);
  void close(String id) => engine.close(id);
  void pause(String id) => engine.pause(id);
  void resume(String id) => engine.resume(id);
  WorkflowSnapshot saveState(String id) => engine.saveState(id);
  void restoreState(String id, String snapshot) =>
      engine.restoreState(id, snapshot);
  void replay(String id, String snapshot) => engine.replay(id, snapshot);
  bool undoStep(String id) => engine.undoStep(id);
  bool redoStep(String id) => engine.redoStep(id);
  List<String> diagnostics(String id) => engine.diagnostics(id);
  List<ChecklistItem> checklist(String id) => engine.checklist(id);
  WorkflowRecommendation advise(String id) => engine.advise(id);
}
