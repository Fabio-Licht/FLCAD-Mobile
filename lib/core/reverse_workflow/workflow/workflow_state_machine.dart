import '../models/workflow_models.dart';

class WorkflowStateMachine {
  const WorkflowStateMachine();
  static const transitions = <WorkflowStepState, Set<WorkflowStepState>>{
    WorkflowStepState.ready: {
      WorkflowStepState.running,
      WorkflowStepState.skipped,
      WorkflowStepState.blocked,
      WorkflowStepState.waitingUser,
      WorkflowStepState.waitingKernel,
      WorkflowStepState.waitingValidation,
    },
    WorkflowStepState.running: {
      WorkflowStepState.completed,
      WorkflowStepState.failed,
      WorkflowStepState.paused,
      WorkflowStepState.waitingUser,
      WorkflowStepState.waitingKernel,
      WorkflowStepState.waitingValidation,
    },
    WorkflowStepState.paused: {
      WorkflowStepState.running,
      WorkflowStepState.failed,
    },
    WorkflowStepState.failed: {
      WorkflowStepState.ready,
      WorkflowStepState.running,
      WorkflowStepState.skipped,
    },
    WorkflowStepState.blocked: {
      WorkflowStepState.ready,
      WorkflowStepState.running,
    },
    WorkflowStepState.waitingUser: {
      WorkflowStepState.running,
      WorkflowStepState.skipped,
    },
    WorkflowStepState.waitingKernel: {
      WorkflowStepState.running,
      WorkflowStepState.failed,
    },
    WorkflowStepState.waitingValidation: {
      WorkflowStepState.running,
      WorkflowStepState.failed,
    },
    WorkflowStepState.completed: {},
    WorkflowStepState.skipped: {},
  };
  void transition(WorkflowStep step, WorkflowStepState next) {
    if (!(transitions[step.state] ?? {}).contains(next)) {
      throw StateError(
        'Invalid workflow step transition: ${step.state.name} -> ${next.name}',
      );
    }
    step.state = next;
    if (next == WorkflowStepState.running) {
      step.startedAt ??= DateTime.now().toUtc();
    }
    if (next == WorkflowStepState.completed ||
        next == WorkflowStepState.skipped) {
      step.completedAt = DateTime.now().toUtc();
    }
  }
}
