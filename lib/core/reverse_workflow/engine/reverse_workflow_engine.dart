import '../advisor/workflow_advisor.dart';
import '../analytics/workflow_analytics.dart';
import '../graph/workflow_graph.dart';
import '../history/workflow_history.dart';
import '../history/workflow_timeline.dart';
import '../models/workflow_models.dart';
import '../repository/workflow_repository.dart';
import '../runtime/reverse_workflow_runtime.dart';
import '../validation/workflow_validation.dart';
import '../workflow/reverse_checklist.dart';
import '../workflow/workflow_state_machine.dart';

class ReverseWorkflowEngine {
  ReverseWorkflowEngine({
    required this.repository,
    ReverseWorkflowRuntime? runtime,
    WorkflowAnalytics? analytics,
    WorkflowHistory? history,
    WorkflowTimeline? timeline,
  }) : runtime = runtime ?? ReverseWorkflowRuntime(),
       analytics = analytics ?? WorkflowAnalytics(),
       history = history ?? WorkflowHistory(),
       timeline = timeline ?? WorkflowTimeline();
  final WorkflowRepository repository;
  final ReverseWorkflowRuntime runtime;
  final WorkflowAnalytics analytics;
  final WorkflowHistory history;
  final WorkflowTimeline timeline;
  final graph = WorkflowGraph();
  final Map<String, ReverseWorkflow> workflows = {};
  final Map<String, WorkflowSnapshot> snapshots = {};
  final Map<String, List<WorkflowSnapshot>> _undo = {}, _redo = {};
  final machine = const WorkflowStateMachine();
  final validator = const WorkflowValidator();
  ReverseWorkflow create(String projectId, String name) {
    final workflow = ReverseWorkflow(projectId: projectId, name: name);
    workflows[workflow.id] = workflow;
    graph.build(workflow);
    _undo[workflow.id] = [];
    _redo[workflow.id] = [];
    analytics.workflows++;
    history.record(WorkflowHistoryAction.create, workflow.id);
    return workflow;
  }

  ReverseWorkflow open(String id) {
    final workflow = _get(id);
    if (workflow.state == ReverseWorkflowState.closed) {
      throw StateError('Closed workflow cannot be reopened without restore');
    }
    workflow.state = ReverseWorkflowState.open;
    workflow.updatedAt = DateTime.now().toUtc();
    analytics.opens++;
    history.record(WorkflowHistoryAction.open, id);
    return workflow;
  }

  void close(String id) {
    final workflow = _get(id);
    workflow.state = ReverseWorkflowState.closed;
    workflow.updatedAt = DateTime.now().toUtc();
    history.record(WorkflowHistoryAction.close, id);
  }

  void pause(String id) {
    final workflow = _get(id);
    _captureUndo(workflow);
    workflow.state = ReverseWorkflowState.paused;
    if (workflow.currentStep.state == WorkflowStepState.running) {
      machine.transition(workflow.currentStep, WorkflowStepState.paused);
    }
    analytics.pauses++;
    history.record(WorkflowHistoryAction.pause, id);
  }

  void resume(String id) {
    final workflow = _get(id);
    _captureUndo(workflow);
    workflow.state = ReverseWorkflowState.running;
    if (workflow.currentStep.state == WorkflowStepState.paused) {
      machine.transition(workflow.currentStep, WorkflowStepState.running);
    }
    analytics.resumes++;
    history.record(WorkflowHistoryAction.resume, id);
  }

  void startCurrentStep(String id) {
    final workflow = _get(id);
    _ensureActive(workflow);
    _captureUndo(workflow);
    machine.transition(workflow.currentStep, WorkflowStepState.running);
    workflow.state = ReverseWorkflowState.running;
    workflow.updatedAt = DateTime.now().toUtc();
    history.record(
      WorkflowHistoryAction.step,
      id,
      step: workflow.currentStep.type,
      result: 'running',
    );
  }

  void setCurrentStepState(
    String id,
    WorkflowStepState state, {
    String? problem,
  }) {
    final workflow = _get(id);
    _captureUndo(workflow);
    machine.transition(workflow.currentStep, state);
    if (problem != null) workflow.currentStep.problems.add(problem);
    workflow.updatedAt = DateTime.now().toUtc();
  }

  void completeCurrentStep(
    String id, {
    required String user,
    required String result,
    double score = 0,
    double gains = 0,
    List<String> problems = const [],
    List<String> observations = const [],
  }) {
    final workflow = _get(id), step = workflow.currentStep;
    _captureUndo(workflow);
    if (step.state == WorkflowStepState.ready) {
      machine.transition(step, WorkflowStepState.running);
    }
    machine.transition(step, WorkflowStepState.completed);
    step
      ..result = result
      ..score = score
      ..gains = gains
      ..problems.addAll(problems)
      ..observations.addAll(observations);
    final duration = step.startedAt == null
        ? 0
        : step.completedAt!.difference(step.startedAt!).inMicroseconds;
    timeline.add(
      WorkflowTimelineEntry(
        workflowId: id,
        step: step.type,
        user: user,
        result: result,
        score: score,
        gains: gains,
        problems: problems,
        observations: observations,
        durationMicros: duration,
      ),
    );
    analytics.timelineUpdates++;
    analytics.totalDurationMicros += duration;
    history.record(
      WorkflowHistoryAction.step,
      id,
      step: step.type,
      result: result,
    );
    if (workflow.currentIndex < workflow.steps.length - 1) {
      workflow.currentIndex++;
    } else {
      workflow.state = ReverseWorkflowState.completed;
      analytics.completions++;
    }
    workflow.updatedAt = DateTime.now().toUtc();
  }

  void skipCurrentStep(
    String id, {
    required String user,
    String reason = 'optional',
  }) {
    final workflow = _get(id), step = workflow.currentStep;
    if (!step.optional) {
      throw StateError(
        'Required workflow step cannot be skipped: ${step.type.name}',
      );
    }
    _captureUndo(workflow);
    machine.transition(step, WorkflowStepState.skipped);
    timeline.add(
      WorkflowTimelineEntry(
        workflowId: id,
        step: step.type,
        user: user,
        result: 'skipped',
        score: step.score,
        gains: 0,
        problems: const [],
        observations: [reason],
        durationMicros: 0,
      ),
    );
    analytics.timelineUpdates++;
    if (workflow.currentIndex < workflow.steps.length - 1) {
      workflow.currentIndex++;
    }
  }

  WorkflowSnapshot saveState(String id) {
    final snapshot = _snapshot(_get(id));
    snapshots[snapshot.id] = snapshot;
    analytics.snapshots++;
    history.record(WorkflowHistoryAction.save, id, result: snapshot.id);
    return snapshot;
  }

  void restoreState(String id, String snapshotId) {
    final workflow = _get(id),
        snapshot =
            snapshots[snapshotId] ??
            (throw StateError('Unknown workflow snapshot: $snapshotId'));
    if (snapshot.workflowId != id) {
      throw StateError('Snapshot belongs to another workflow');
    }
    _apply(workflow, snapshot);
    analytics.restores++;
    history.record(WorkflowHistoryAction.restore, id, result: snapshotId);
  }

  void replay(String id, String snapshotId) {
    restoreState(id, snapshotId);
    analytics.replays++;
    history.record(WorkflowHistoryAction.replay, id, result: snapshotId);
  }

  bool undoStep(String id) {
    final workflow = _get(id), stack = _undo[id]!;
    if (stack.isEmpty) return false;
    _redo[id]!.add(_snapshot(workflow));
    _apply(workflow, stack.removeLast());
    analytics.undo++;
    history.record(WorkflowHistoryAction.undo, id);
    return true;
  }

  bool redoStep(String id) {
    final workflow = _get(id), stack = _redo[id]!;
    if (stack.isEmpty) return false;
    _undo[id]!.add(_snapshot(workflow));
    _apply(workflow, stack.removeLast());
    analytics.redo++;
    history.record(WorkflowHistoryAction.redo, id);
    return true;
  }

  List<String> diagnostics(String id) {
    final workflow = _get(id),
        issues = validator
            .validate(workflow)
            .issues
            .map((e) => e.message)
            .toList();
    issues.addAll(workflow.currentStep.problems);
    workflow.diagnostics
      ..clear()
      ..addAll(issues);
    history.record(
      WorkflowHistoryAction.diagnostic,
      id,
      result: issues.join('; '),
    );
    if (issues.isNotEmpty) analytics.failures++;
    return List.unmodifiable(issues);
  }

  List<ChecklistItem> checklist(String id) {
    analytics.checklistUpdates++;
    return const ReverseChecklist().build(_get(id));
  }

  WorkflowRecommendation advise(String id) {
    analytics.advisorUpdates++;
    return const WorkflowAdvisor().analyze(_get(id));
  }

  void updateEngineeringStatus(
    String id, {
    required double score,
    required double health,
    Iterable<String> recommendations = const [],
  }) {
    final workflow = _get(id);
    workflow
      ..engineeringScore = score
      ..projectHealth = health
      ..recommendationIds.clear()
      ..recommendationIds.addAll(recommendations)
      ..updatedAt = DateTime.now().toUtc();
  }

  void _captureUndo(ReverseWorkflow workflow) {
    _undo[workflow.id]!.add(_snapshot(workflow));
    _redo[workflow.id]!.clear();
  }

  WorkflowSnapshot _snapshot(ReverseWorkflow w) => WorkflowSnapshot(
    workflowId: w.id,
    currentIndex: w.currentIndex,
    workflowState: w.state,
    stepStates: w.steps.map((e) => e.state).toList(),
    engineeringScore: w.engineeringScore,
    projectHealth: w.projectHealth,
  );
  void _apply(ReverseWorkflow w, WorkflowSnapshot s) {
    w
      ..currentIndex = s.currentIndex
      ..state = s.workflowState
      ..engineeringScore = s.engineeringScore
      ..projectHealth = s.projectHealth
      ..updatedAt = DateTime.now().toUtc();
    for (var i = 0; i < w.steps.length; i++) {
      w.steps[i].state = s.stepStates[i];
    }
  }

  void _ensureActive(ReverseWorkflow w) {
    if ({
      ReverseWorkflowState.closed,
      ReverseWorkflowState.completed,
    }.contains(w.state)) {
      throw StateError('Workflow is not active: ${w.state.name}');
    }
  }

  ReverseWorkflow _get(String id) =>
      workflows[id] ?? (throw StateError('Unknown workflow: $id'));
  Future<void> persist() => repository.save(
    workflows: workflows.values,
    history: history,
    analytics: analytics,
    timeline: timeline,
    snapshots: snapshots,
  );
}
