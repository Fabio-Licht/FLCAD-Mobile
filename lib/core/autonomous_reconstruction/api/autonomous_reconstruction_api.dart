import '../../engineering/services/engineering_service_registry.dart';
import '../../engineering_cognition/models/cognition_models.dart';
import '../advisor/reconstruction_advisor.dart';
import '../cache/workflow_cache.dart';
import '../events/reconstruction_events.dart';
import '../models/reconstruction_models.dart';
import '../orchestrator/autonomous_orchestrator.dart';

class AutonomousReconstructionApi {
  AutonomousReconstructionApi({
    AutonomousReconstructionOrchestrator? orchestrator,
    WorkflowCache? cache,
    AutonomousReconstructionEventBus? events,
  }) : orchestrator = orchestrator ?? AutonomousReconstructionOrchestrator(),
       cache = cache ?? WorkflowCache(),
       events = events ?? AutonomousReconstructionEventBus();
  final AutonomousReconstructionOrchestrator orchestrator;
  final WorkflowCache cache;
  final AutonomousReconstructionEventBus events;
  ReconstructionWorkflow build(CognitionSnapshot cognition) {
    final workflow = orchestrator.build(cognition);
    cache.put(workflow);
    events.publish(
      AutonomousReconstructionEvent(
        'workflowBuilt',
        workflow.id,
        DateTime.now().toUtc(),
        {
          'stages': workflow.stages.length,
          'strategy': workflow.selectedStrategyId,
        },
      ),
    );
    return workflow;
  }

  ReconstructionWorkflow rebuild(CognitionSnapshot cognition, String reason) {
    final workflow = orchestrator.rebuild(cognition, reason: reason);
    cache.put(workflow);
    events.publish(
      AutonomousReconstructionEvent(
        'workflowRebuilt',
        workflow.id,
        DateTime.now().toUtc(),
        {'revision': workflow.revision, 'reason': reason},
      ),
    );
    return workflow;
  }

  ReconstructionWorkflow executeStage(String workflowId, String stageId) {
    final scheduler = orchestrator.scheduler(workflowId),
        stage = scheduler.workflow.stages.firstWhere((s) => s.id == stageId);
    if (stage.type == ReconstructionStageType.surface ||
        stage.type == ReconstructionStageType.cadFeature ||
        stage.type == ReconstructionStageType.solid) {
      throw UnsupportedError(
        'G-009 plans CAD geometry but does not execute ${stage.type.name} stages',
      );
    }
    scheduler.start(stageId);
    events.publish(
      AutonomousReconstructionEvent(
        'stageStarted',
        workflowId,
        DateTime.now().toUtc(),
        {'stageId': stageId},
      ),
    );
    cache.put(scheduler.workflow);
    return scheduler.workflow;
  }

  ReconstructionWorkflow completeStage(String workflowId, String stageId) {
    final scheduler = orchestrator.scheduler(workflowId)..complete(stageId);
    cache.put(scheduler.workflow);
    return scheduler.workflow;
  }

  ReconstructionWorkflow pause(String workflowId) {
    final scheduler = orchestrator.scheduler(workflowId)..pause();
    cache.put(scheduler.workflow);
    return scheduler.workflow;
  }

  ReconstructionWorkflow resume(String workflowId) {
    final scheduler = orchestrator.scheduler(workflowId)..resume();
    cache.put(scheduler.workflow);
    return scheduler.workflow;
  }

  ReconstructionUiState advisor(String workflowId) =>
      const ReconstructionAdvisor().state(
        orchestrator.scheduler(workflowId).workflow,
      );
  void install(EngineeringServiceRegistry services) =>
      services.register<AutonomousReconstructionApi>(this);
}
