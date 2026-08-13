enum ProfessionalWorkflowStage {
  openProject,
  importStl,
  analyzeMesh,
  assessQuality,
  recognizeRegions,
  createReferences,
  createSketches,
  planSurfaces,
  planFeatures,
  planCad,
  export,
}

enum ProfessionalStageStatus {
  locked,
  ready,
  active,
  completed,
  blocked,
  failed,
}

enum ProfessionalArtifactKind {
  project,
  mesh,
  region,
  reference,
  sketch,
  surfacePlan,
  featurePlan,
  cadPlan,
  export,
}

class WorkflowEvidence {
  const WorkflowEvidence({
    required this.id,
    required this.description,
    required this.source,
    required this.weight,
  });
  final String id, description, source;
  final double weight;
}

class ExplainableDecision {
  const ExplainableDecision({
    required this.why,
    required this.evidence,
    required this.alternatives,
    required this.confidence,
    required this.impact,
  });
  final String why, impact;
  final List<WorkflowEvidence> evidence;
  final List<String> alternatives;
  final double confidence;
}

class ProfessionalWorkflowStep {
  const ProfessionalWorkflowStep({
    required this.stage,
    required this.title,
    required this.status,
    required this.order,
    required this.requires,
    this.progress = 0,
    this.blockReason,
  });
  final ProfessionalWorkflowStage stage;
  final String title;
  final ProfessionalStageStatus status;
  final int order;
  final List<ProfessionalWorkflowStage> requires;
  final double progress;
  final String? blockReason;
  ProfessionalWorkflowStep copyWith({
    ProfessionalStageStatus? status,
    double? progress,
    String? blockReason,
  }) => ProfessionalWorkflowStep(
    stage: stage,
    title: title,
    status: status ?? this.status,
    order: order,
    requires: requires,
    progress: progress ?? this.progress,
    blockReason: blockReason ?? this.blockReason,
  );
}

class ProfessionalArtifact {
  const ProfessionalArtifact({
    required this.id,
    required this.projectId,
    required this.name,
    required this.kind,
    required this.origin,
    required this.dna,
    required this.confidence,
    this.dependencies = const [],
    this.referenceIds = const [],
    this.analytics = const {},
  });
  final String id, projectId, name, origin, dna;
  final ProfessionalArtifactKind kind;
  final double confidence;
  final List<String> dependencies, referenceIds;
  final Map<String, num> analytics;
}

class WorkflowRecommendation {
  const WorkflowRecommendation({
    required this.id,
    required this.stage,
    required this.title,
    required this.actionLabel,
    required this.decision,
    this.targetArtifactId,
  });
  final String id, title, actionLabel;
  final ProfessionalWorkflowStage stage;
  final ExplainableDecision decision;
  final String? targetArtifactId;
}

class EngineeringTimelineEntry {
  const EngineeringTimelineEntry({
    required this.sequence,
    required this.timestamp,
    required this.type,
    required this.title,
    required this.description,
    this.artifactId,
    this.replayable = true,
  });
  final int sequence;
  final DateTime timestamp;
  final String type, title, description;
  final String? artifactId;
  final bool replayable;
}

class InspectorSnapshot {
  const InspectorSnapshot({
    this.meshQuality = 0,
    this.openRegions = 0,
    this.normalConsistency = 0,
    this.coverage = 0,
    this.confidence = 0,
    this.reconstructionReadiness = 0,
    this.notes = const [],
  });
  final double meshQuality,
      normalConsistency,
      coverage,
      confidence,
      reconstructionReadiness;
  final int openRegions;
  final List<String> notes;
}

class WorkflowDashboardSnapshot {
  const WorkflowDashboardSnapshot({
    required this.progress,
    required this.coverage,
    required this.regionCount,
    required this.hypothesisCount,
    required this.strategy,
    required this.aiStatus,
    required this.plannedOperations,
  });
  final double progress, coverage;
  final int regionCount, hypothesisCount, plannedOperations;
  final String strategy, aiStatus;
}

class ProfessionalWorkflowState {
  const ProfessionalWorkflowState({
    required this.projectId,
    required this.steps,
    required this.artifacts,
    required this.timeline,
    required this.recommendations,
    required this.inspector,
    required this.dashboard,
    required this.updatedAt,
    this.selectedArtifactId,
    this.processing = false,
    this.lastError,
  });
  final String projectId;
  final List<ProfessionalWorkflowStep> steps;
  final List<ProfessionalArtifact> artifacts;
  final List<EngineeringTimelineEntry> timeline;
  final List<WorkflowRecommendation> recommendations;
  final InspectorSnapshot inspector;
  final WorkflowDashboardSnapshot dashboard;
  final DateTime updatedAt;
  final String? selectedArtifactId, lastError;
  final bool processing;
  ProfessionalWorkflowStage? get currentStage {
    for (final step in steps) {
      if (step.status == ProfessionalStageStatus.active ||
          step.status == ProfessionalStageStatus.ready) {
        return step.stage;
      }
    }
    return null;
  }

  double get progress => steps.isEmpty
      ? 0
      : steps.fold<double>(0, (sum, step) => sum + step.progress) /
            steps.length;
  ProfessionalArtifact? get selectedArtifact {
    for (final artifact in artifacts) {
      if (artifact.id == selectedArtifactId) return artifact;
    }
    return null;
  }

  ProfessionalWorkflowState copyWith({
    List<ProfessionalWorkflowStep>? steps,
    List<ProfessionalArtifact>? artifacts,
    List<EngineeringTimelineEntry>? timeline,
    List<WorkflowRecommendation>? recommendations,
    InspectorSnapshot? inspector,
    WorkflowDashboardSnapshot? dashboard,
    String? selectedArtifactId,
    bool clearSelection = false,
    bool? processing,
    String? lastError,
    bool clearError = false,
    DateTime? updatedAt,
  }) => ProfessionalWorkflowState(
    projectId: projectId,
    steps: steps ?? this.steps,
    artifacts: artifacts ?? this.artifacts,
    timeline: timeline ?? this.timeline,
    recommendations: recommendations ?? this.recommendations,
    inspector: inspector ?? this.inspector,
    dashboard: dashboard ?? this.dashboard,
    selectedArtifactId: clearSelection
        ? null
        : selectedArtifactId ?? this.selectedArtifactId,
    processing: processing ?? this.processing,
    lastError: clearError ? null : lastError ?? this.lastError,
    updatedAt: updatedAt ?? DateTime.now(),
  );
}
