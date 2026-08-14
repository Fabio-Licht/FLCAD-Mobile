import '../../utils/id_generator.dart';

enum ReverseWorkflowStepType {
  importMesh,
  recognition,
  referenceGeometry,
  alignment,
  validation,
  sketch,
  constraintSolve,
  profileRecognition,
  featureCreation,
  validationUpdate,
  engineeringReview,
  projectComplete,
}

enum WorkflowStepState {
  ready,
  running,
  paused,
  completed,
  failed,
  skipped,
  blocked,
  waitingUser,
  waitingKernel,
  waitingValidation,
}

enum ReverseWorkflowState {
  created,
  open,
  running,
  paused,
  closed,
  completed,
  failed,
}

class WorkflowStep {
  WorkflowStep(this.type, {this.optional = false})
    : id = 'workflow-step:${IdGenerator.generate()}';
  final String id;
  final ReverseWorkflowStepType type;
  final bool optional;
  WorkflowStepState state = WorkflowStepState.ready;
  DateTime? startedAt, completedAt;
  String? result;
  double score = 0, gains = 0;
  final List<String> problems = [], observations = [];
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'optional': optional,
    'state': state.name,
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'result': result,
    'score': score,
    'gains': gains,
    'problems': problems,
    'observations': observations,
  };
}

class ReverseWorkflow {
  ReverseWorkflow({required this.projectId, required this.name, String? id})
    : id = id ?? 'reverse-workflow:${IdGenerator.generate()}',
      createdAt = DateTime.now().toUtc(),
      steps = [
        for (final type in ReverseWorkflowStepType.values)
          WorkflowStep(
            type,
            optional: {
              ReverseWorkflowStepType.constraintSolve,
              ReverseWorkflowStepType.profileRecognition,
            }.contains(type),
          ),
      ];
  final String id, projectId;
  String name;
  final DateTime createdAt;
  DateTime updatedAt = DateTime.now().toUtc();
  ReverseWorkflowState state = ReverseWorkflowState.created;
  final List<WorkflowStep> steps;
  int currentIndex = 0;
  double engineeringScore = 0, projectHealth = 0;
  final List<String> recommendationIds = [], diagnostics = [];
  WorkflowStep get currentStep =>
      steps[currentIndex.clamp(0, steps.length - 1)];
  double get progress =>
      steps
          .where(
            (s) =>
                s.state == WorkflowStepState.completed ||
                s.state == WorkflowStepState.skipped,
          )
          .length /
      steps.length;
  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'state': state.name,
    'currentIndex': currentIndex,
    'engineeringScore': engineeringScore,
    'projectHealth': projectHealth,
    'recommendationIds': recommendationIds,
    'diagnostics': diagnostics,
    'steps': steps.map((e) => e.toJson()).toList(),
    'progress': progress,
  };
}

class WorkflowSnapshot {
  WorkflowSnapshot({
    required this.workflowId,
    required this.currentIndex,
    required this.workflowState,
    required this.stepStates,
    required this.engineeringScore,
    required this.projectHealth,
    String? id,
  }) : id = id ?? 'workflow-snapshot:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id, workflowId;
  final int currentIndex;
  final ReverseWorkflowState workflowState;
  final List<WorkflowStepState> stepStates;
  final double engineeringScore, projectHealth;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'workflowId': workflowId,
    'currentIndex': currentIndex,
    'workflowState': workflowState.name,
    'stepStates': stepStates.map((e) => e.name).toList(),
    'engineeringScore': engineeringScore,
    'projectHealth': projectHealth,
    'timestamp': timestamp.toIso8601String(),
  };
}
