import '../../engineering_intelligence/models/intelligence_models.dart';
import '../../reverse_workflow/models/workflow_models.dart';
import '../models/adaptive_studio_models.dart';
import '../workspace/adaptive_workspace_engine.dart';

class AdaptiveStudioApi {
  const AdaptiveStudioApi(this.engine);
  final AdaptiveWorkspaceEngine engine;
  List<AdaptiveWorkspaceState> get workspaces =>
      List.unmodifiable(engine.workspaces.values);
  AdaptiveWorkspaceState create(String projectId) => engine.create(projectId);
  void adaptTo(
    String id,
    ReverseWorkflow workflow, {
    Iterable<EngineeringRecommendation> recommendations = const [],
  }) => engine.adaptTo(id, workflow, recommendations: recommendations);
  WorkspaceMemory saveLayout(String id) => engine.saveLayout(id);
  void restoreLayout(String id, String memory) =>
      engine.restoreLayout(id, memory);
}
