import '../models/mesh_models.dart';
import '../../reverse_session/api/reverse_session_api.dart';
import '../../reverse_workflow/api/reverse_workflow_api.dart';

abstract interface class MeshIntegration {
  void onMeshImported(MeshEntity mesh);
  void onMeshClosed(MeshEntity mesh);
}

class OfficialMeshIntegration implements MeshIntegration {
  OfficialMeshIntegration({
    required this.workflows,
    required this.workflowId,
    required this.sessions,
    required this.sessionId,
    required this.project,
    required this.dashboard,
  });
  final ReverseWorkflowApi workflows;
  final String workflowId;
  final ReverseSessionApi sessions;
  final String sessionId;
  final Map<String, dynamic> project, dashboard;
  @override
  void onMeshImported(MeshEntity mesh) {
    final workflow =
        workflows.engine.workflows[workflowId] ??
        (throw StateError('Unknown workflow: $workflowId'));
    if (workflow.currentStep.type.name != 'importMesh') {
      throw StateError('Workflow is not at Import Mesh');
    }
    workflows.engine.completeCurrentStep(
      workflowId,
      user: sessions.engine.sessions[sessionId]!.user,
      result: mesh.id,
      score: 1,
    );
    final session =
        sessions.engine.sessions[sessionId] ??
        (throw StateError('Unknown session: $sessionId'));
    session.context.state['mesh'] = mesh.toJson();
    session.context.state['workflow'] = workflow.toJson();
    session.context.state['selectionAvailable'] = true;
    sessions.engine.record(sessionId, 'Import STL', result: mesh.id);
    project['activeMesh'] = mesh.toJson();
    dashboard['mesh'] = mesh.toJson();
    dashboard['recognitionStarted'] = false;
  }

  @override
  void onMeshClosed(MeshEntity mesh) {
    project['activeMesh'] = null;
    dashboard['meshState'] = 'closed';
    sessions.engine.record(sessionId, 'Close Mesh', result: mesh.id);
  }
}
