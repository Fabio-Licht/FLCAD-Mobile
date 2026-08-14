import '../../utils/id_generator.dart';
import '../models/workflow_models.dart';

class WorkflowTimelineEntry {
  WorkflowTimelineEntry({
    required this.workflowId,
    required this.step,
    required this.user,
    required this.result,
    required this.score,
    required this.gains,
    required this.problems,
    required this.observations,
    required this.durationMicros,
  }) : id = 'workflow-timeline:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id, workflowId, user, result;
  final ReverseWorkflowStepType step;
  final DateTime timestamp;
  final double score, gains;
  final List<String> problems, observations;
  final int durationMicros;
  Map<String, dynamic> toJson() => {
    'id': id,
    'workflowId': workflowId,
    'step': step.name,
    'user': user,
    'result': result,
    'score': score,
    'gains': gains,
    'problems': problems,
    'observations': observations,
    'durationMicros': durationMicros,
    'timestamp': timestamp.toIso8601String(),
  };
}

class WorkflowTimeline {
  final List<WorkflowTimelineEntry> entries = [];
  void add(WorkflowTimelineEntry entry) => entries.add(entry);
}
