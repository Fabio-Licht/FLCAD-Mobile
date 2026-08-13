import '../../engineering_cognition/models/cognition_models.dart';

enum ReconstructionStageType {
  project,
  mesh,
  reference,
  sketch,
  surface,
  cadFeature,
  solid,
  validation,
}

enum ReconstructionStageStatus {
  pending,
  ready,
  running,
  completed,
  paused,
  blocked,
  failed,
  cancelled,
}

enum ReconstructionRisk { low, medium, high, critical }

class ReconstructionEvidence {
  const ReconstructionEvidence(
    this.id,
    this.description,
    this.value,
    this.source,
  );
  final String id, description, source;
  final double value;
}

class ReconstructionDecision {
  const ReconstructionDecision({
    required this.confidence,
    required this.risk,
    required this.evidence,
    required this.alternatives,
    required this.impact,
    required this.explanation,
  });
  final double confidence;
  final ReconstructionRisk risk;
  final List<ReconstructionEvidence> evidence;
  final List<String> alternatives;
  final String impact, explanation;
}

class ReconstructionStage {
  const ReconstructionStage({
    required this.id,
    required this.type,
    required this.name,
    required this.order,
    required this.priority,
    required this.dependencies,
    required this.sourceIds,
    required this.decision,
    this.status = ReconstructionStageStatus.pending,
    this.parallelGroup,
  });
  final String id, name;
  final ReconstructionStageType type;
  final int order, priority;
  final List<String> dependencies, sourceIds;
  final ReconstructionDecision decision;
  final ReconstructionStageStatus status;
  final String? parallelGroup;
  ReconstructionStage copyWith({
    ReconstructionStageStatus? status,
    int? order,
    List<String>? dependencies,
  }) => ReconstructionStage(
    id: id,
    type: type,
    name: name,
    order: order ?? this.order,
    priority: priority,
    dependencies: dependencies ?? this.dependencies,
    sourceIds: sourceIds,
    decision: decision,
    status: status ?? this.status,
    parallelGroup: parallelGroup,
  );
}

class ReconstructionWorkflow {
  const ReconstructionWorkflow({
    required this.id,
    required this.projectId,
    required this.meshId,
    required this.revision,
    required this.stages,
    required this.selectedStrategyId,
    required this.createdAt,
    required this.updatedAt,
    this.paused = false,
  });
  final String id, projectId, meshId, selectedStrategyId;
  final int revision;
  final List<ReconstructionStage> stages;
  final DateTime createdAt, updatedAt;
  final bool paused;
  double get progress => stages.isEmpty
      ? 0
      : stages
                .where((s) => s.status == ReconstructionStageStatus.completed)
                .length /
            stages.length;
  ReconstructionStage? get nextStep {
    final ready =
        stages
            .where((s) => s.status == ReconstructionStageStatus.ready)
            .toList()
          ..sort((a, b) {
            final p = b.priority.compareTo(a.priority);
            return p != 0 ? p : a.order.compareTo(b.order);
          });
    return ready.isEmpty ? null : ready.first;
  }

  ReconstructionWorkflow copyWith({
    List<ReconstructionStage>? stages,
    int? revision,
    DateTime? updatedAt,
    bool? paused,
    String? selectedStrategyId,
  }) => ReconstructionWorkflow(
    id: id,
    projectId: projectId,
    meshId: meshId,
    revision: revision ?? this.revision,
    stages: stages ?? this.stages,
    selectedStrategyId: selectedStrategyId ?? this.selectedStrategyId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    paused: paused ?? this.paused,
  );
}

class WorkflowTimelineEntry {
  const WorkflowTimelineEntry(
    this.sequence,
    this.stageId,
    this.status,
    this.timestamp,
    this.reason,
  );
  final int sequence;
  final String stageId, reason;
  final ReconstructionStageStatus status;
  final DateTime timestamp;
}

class ReconstructionPlanInput {
  const ReconstructionPlanInput(
    this.cognition, {
    this.previous,
    this.changeReason,
  });
  final CognitionSnapshot cognition;
  final ReconstructionWorkflow? previous;
  final String? changeReason;
}

class ReconstructionUiState {
  const ReconstructionUiState(
    this.workflowId,
    this.progress,
    this.nextStep,
    this.dependencies,
    this.confidence,
    this.alternatives,
    this.explanation,
    this.paused,
  );
  final String workflowId;
  final double progress, confidence;
  final String? nextStep;
  final List<String> dependencies, alternatives;
  final String explanation;
  final bool paused;
}
