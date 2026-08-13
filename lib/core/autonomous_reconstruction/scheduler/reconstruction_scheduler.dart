import '../dependencies/dependency_graph.dart';
import '../models/reconstruction_models.dart';
import '../timeline/workflow_timeline.dart';

class ReconstructionScheduler {
  ReconstructionScheduler(this.workflow, {WorkflowTimeline? timeline})
    : timeline = timeline ?? WorkflowTimeline() {
    _refresh();
  }
  ReconstructionWorkflow workflow;
  final WorkflowTimeline timeline;
  List<ReconstructionStage> get executable {
    if (workflow.paused) return const [];
    return workflow.stages
        .where((s) => s.status == ReconstructionStageStatus.ready)
        .toList()
      ..sort((a, b) {
        final p = b.priority.compareTo(a.priority);
        return p != 0 ? p : a.order.compareTo(b.order);
      });
  }

  List<List<ReconstructionStage>> get parallelBatches {
    final byGroup = <String, List<ReconstructionStage>>{};
    for (final stage in executable) {
      (byGroup[stage.parallelGroup ?? stage.id] ??= []).add(stage);
    }
    return byGroup.values.toList();
  }

  void start(String id) {
    _transition(
      id,
      ReconstructionStageStatus.running,
      'Stage execution started',
    );
  }

  void complete(String id) {
    _transition(id, ReconstructionStageStatus.completed, 'Stage completed');
    _refresh();
  }

  void fail(String id, String reason) {
    _transition(id, ReconstructionStageStatus.failed, reason);
    _blockDependents(id, reason);
  }

  void cancel(String id) {
    _transition(id, ReconstructionStageStatus.cancelled, 'Stage cancelled');
    _blockDependents(id, 'Dependency cancelled');
  }

  void pause() {
    workflow = workflow.copyWith(
      paused: true,
      updatedAt: DateTime.now().toUtc(),
    );
    for (final stage in workflow.stages.where(
      (s) => s.status == ReconstructionStageStatus.running,
    )) {
      _transition(
        stage.id,
        ReconstructionStageStatus.paused,
        'Workflow paused',
      );
    }
  }

  void resume() {
    workflow = workflow.copyWith(
      paused: false,
      updatedAt: DateTime.now().toUtc(),
    );
    final stages = workflow.stages
        .map(
          (s) => s.status == ReconstructionStageStatus.paused
              ? s.copyWith(status: ReconstructionStageStatus.ready)
              : s,
        )
        .toList();
    workflow = workflow.copyWith(stages: stages);
    _refresh();
  }

  void _transition(String id, ReconstructionStageStatus status, String reason) {
    final current = workflow.stages.firstWhere((s) => s.id == id);
    if (!_allowed(current.status, status)) {
      throw StateError(
        'Invalid stage transition ${current.status.name} -> ${status.name}',
      );
    }
    workflow = workflow.copyWith(
      stages: workflow.stages
          .map((s) => s.id == id ? s.copyWith(status: status) : s)
          .toList(),
      updatedAt: DateTime.now().toUtc(),
    );
    timeline.record(id, status, reason);
  }

  bool _allowed(ReconstructionStageStatus from, ReconstructionStageStatus to) =>
      switch (from) {
        ReconstructionStageStatus.pending => [
          ReconstructionStageStatus.ready,
          ReconstructionStageStatus.blocked,
          ReconstructionStageStatus.cancelled,
        ].contains(to),
        ReconstructionStageStatus.ready => [
          ReconstructionStageStatus.running,
          ReconstructionStageStatus.cancelled,
          ReconstructionStageStatus.blocked,
        ].contains(to),
        ReconstructionStageStatus.running => [
          ReconstructionStageStatus.completed,
          ReconstructionStageStatus.failed,
          ReconstructionStageStatus.paused,
          ReconstructionStageStatus.cancelled,
        ].contains(to),
        ReconstructionStageStatus.paused => [
          ReconstructionStageStatus.ready,
          ReconstructionStageStatus.cancelled,
        ].contains(to),
        _ => false,
      };
  void _refresh() {
    final graph = ReconstructionDependencyGraph(workflow.stages),
        states = {for (final s in workflow.stages) s.id: s.status},
        updated = workflow.stages.map((s) {
          if (s.status == ReconstructionStageStatus.pending &&
              graph.dependenciesCompleted(s.id, states)) {
            timeline.record(
              s.id,
              ReconstructionStageStatus.ready,
              'All dependencies completed',
            );
            return s.copyWith(status: ReconstructionStageStatus.ready);
          }
          return s;
        }).toList();
    workflow = workflow.copyWith(
      stages: updated,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  void _blockDependents(String id, String reason) {
    final graph = ReconstructionDependencyGraph(workflow.stages),
        affected = <String>{},
        queue = [id];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final d in graph.dependentsOf(current)) {
        if (affected.add(d)) queue.add(d);
      }
    }
    workflow = workflow.copyWith(
      stages: workflow.stages
          .map(
            (s) =>
                affected.contains(s.id) &&
                    [
                      ReconstructionStageStatus.pending,
                      ReconstructionStageStatus.ready,
                    ].contains(s.status)
                ? s.copyWith(status: ReconstructionStageStatus.blocked)
                : s,
          )
          .toList(),
    );
    for (final stage in affected) {
      timeline.record(stage, ReconstructionStageStatus.blocked, reason);
    }
  }
}
