import '../../engineering_cognition/models/cognition_models.dart';
import '../advisor/reconstruction_advisor.dart';
import '../models/reconstruction_models.dart';
import '../planner/master_planner.dart';
import '../scheduler/reconstruction_scheduler.dart';
import '../validation/workflow_validator.dart';

class AutonomousReconstructionOrchestrator {
  AutonomousReconstructionOrchestrator({
    ReconstructionMasterPlanner? planner,
    ReconstructionWorkflowValidator? validator,
  }) : planner = planner ?? const ReconstructionMasterPlanner(),
       validator = validator ?? const ReconstructionWorkflowValidator();
  final ReconstructionMasterPlanner planner;
  final ReconstructionWorkflowValidator validator;
  final Map<String, ReconstructionScheduler> _schedulers = {};
  ReconstructionWorkflow build(CognitionSnapshot cognition) {
    final workflow = planner.build(ReconstructionPlanInput(cognition)),
        validation = validator.validate(workflow);
    if (!validation.valid) throw StateError(validation.issues.join('; '));
    final scheduler = ReconstructionScheduler(workflow);
    _schedulers[workflow.id] = scheduler;
    return scheduler.workflow;
  }

  ReconstructionWorkflow rebuild(
    CognitionSnapshot cognition, {
    required String reason,
  }) {
    final existing = _schedulers.values
            .where((s) => s.workflow.meshId == cognition.meshId)
            .toList(),
        previous = existing.isEmpty ? null : existing.first.workflow,
        workflow = planner.build(
          ReconstructionPlanInput(
            cognition,
            previous: previous,
            changeReason: reason,
          ),
        ),
        scheduler = ReconstructionScheduler(workflow);
    _schedulers[workflow.id] = scheduler;
    return scheduler.workflow;
  }

  ReconstructionScheduler scheduler(String workflowId) =>
      _schedulers[workflowId] ??
      (throw StateError('Workflow not loaded: $workflowId'));
  ReconstructionUiState advisor(String workflowId) =>
      const ReconstructionAdvisor().state(scheduler(workflowId).workflow);
}
