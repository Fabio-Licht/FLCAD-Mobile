import '../../engineering/context/engineering_context.dart';
import '../../engineering/events/engineering_event_bus.dart';
import '../../engineering/graph/engineering_graph.dart';
import '../../engineering_cognition/models/cognition_models.dart';
import '../api/autonomous_reconstruction_api.dart';
import '../models/reconstruction_models.dart';

class AutonomousReconstructionIntegration {
  const AutonomousReconstructionIntegration(this.api);
  final AutonomousReconstructionApi api;
  Future<ReconstructionWorkflow> build(
    EngineeringContext context,
    CognitionSnapshot cognition,
  ) async {
    final workflow = api.build(cognition);
    context.history.record(
      projectId: context.projectId,
      entityId: workflow.id,
      domain: 'autonomous_reconstruction',
      action: 'planned',
      snapshot: workflow,
    );
    for (final stage in workflow.stages) {
      context.graph.addNode(
        EngineeringGraphNode(
          stage.id,
          _nodeType(stage.type),
          metadata: {
            'status': stage.status.name,
            'confidence': stage.decision.confidence,
          },
        ),
      );
    }
    for (final stage in workflow.stages) {
      for (final dependency in stage.dependencies) {
        if (!context.graph.edges.any(
          (e) => e.sourceId == dependency && e.targetId == stage.id,
        )) {
          context.graph.connect(
            EngineeringGraphEdge(dependency, stage.id, 'requiredBy'),
          );
        }
      }
    }
    await context.events.publish(
      EngineeringEvent(
        id: 'autonomous:${DateTime.now().microsecondsSinceEpoch}',
        projectId: context.projectId,
        domain: 'autonomous_reconstruction',
        type: 'workflowPlanned',
        entityId: workflow.id,
        timestamp: DateTime.now().toUtc(),
        payload: {
          'revision': workflow.revision,
          'stages': workflow.stages.length,
        },
      ),
    );
    return workflow;
  }

  EngineeringNodeType _nodeType(ReconstructionStageType type) => switch (type) {
    ReconstructionStageType.project => EngineeringNodeType.project,
    ReconstructionStageType.mesh => EngineeringNodeType.mesh,
    ReconstructionStageType.reference => EngineeringNodeType.reference,
    ReconstructionStageType.sketch => EngineeringNodeType.sketch,
    ReconstructionStageType.surface => EngineeringNodeType.surface,
    ReconstructionStageType.cadFeature => EngineeringNodeType.feature,
    ReconstructionStageType.solid => EngineeringNodeType.solid,
    ReconstructionStageType.validation => EngineeringNodeType.inspection,
  };
}
