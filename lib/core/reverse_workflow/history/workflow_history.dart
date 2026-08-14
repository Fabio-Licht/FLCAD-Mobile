import '../../utils/id_generator.dart';
import '../models/workflow_models.dart';

enum WorkflowHistoryAction {
  create,
  open,
  close,
  pause,
  resume,
  save,
  restore,
  replay,
  step,
  undo,
  redo,
  diagnostic,
}

class WorkflowHistoryEntry {
  WorkflowHistoryEntry(this.action, this.workflowId, {this.step, this.result})
    : id = 'workflow-history:${IdGenerator.generate()}',
      timestamp = DateTime.now().toUtc();
  final String id, workflowId;
  final WorkflowHistoryAction action;
  final ReverseWorkflowStepType? step;
  final String? result;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'workflowId': workflowId,
    'action': action.name,
    'step': step?.name,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
  };
}

class WorkflowHistory {
  final List<WorkflowHistoryEntry> entries = [];
  void record(
    WorkflowHistoryAction action,
    String workflowId, {
    ReverseWorkflowStepType? step,
    String? result,
  }) => entries.add(
    WorkflowHistoryEntry(action, workflowId, step: step, result: result),
  );
}
