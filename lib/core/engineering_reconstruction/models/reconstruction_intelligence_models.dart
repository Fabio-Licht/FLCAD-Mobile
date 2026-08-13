import '../../professional_recognition/models/professional_recognition_models.dart';

enum ERINodeType {
  reference,
  sketch,
  surface,
  feature,
  solidMilestone,
  validation,
}

enum ERINodeStatus {
  planned,
  ready,
  accepted,
  rejected,
  deferred,
  replaced,
  blocked,
}

enum ERIRisk { low, medium, high, critical }

enum ReconstructionLevel { references, sketches, surfaces, features, solidPlan }

class ERIPlanNode {
  const ERIPlanNode({
    required this.id,
    required this.type,
    required this.level,
    required this.title,
    required this.dependencies,
    required this.alternatives,
    required this.cost,
    required this.risk,
    required this.confidence,
    required this.impact,
    required this.priority,
    required this.explanation,
    required this.sourceIds,
    this.status = ERINodeStatus.planned,
  });
  final String id, title, impact, explanation;
  final ERINodeType type;
  final ReconstructionLevel level;
  final List<String> dependencies, alternatives, sourceIds;
  final double cost, confidence, priority;
  final ERIRisk risk;
  final ERINodeStatus status;
  ERIPlanNode copyWith({
    List<String>? dependencies,
    ERINodeStatus? status,
    double? priority,
    String? title,
  }) => ERIPlanNode(
    id: id,
    type: type,
    level: level,
    title: title ?? this.title,
    dependencies: dependencies ?? this.dependencies,
    alternatives: alternatives,
    cost: cost,
    risk: risk,
    confidence: confidence,
    impact: impact,
    priority: priority ?? this.priority,
    explanation: explanation,
    sourceIds: sourceIds,
    status: status ?? this.status,
  );
}

class ERIStrategy {
  const ERIStrategy({
    required this.id,
    required this.name,
    required this.nodeKinds,
    required this.confidence,
    required this.cost,
    required this.risk,
    required this.explanation,
    required this.score,
  });
  final String id, name, explanation;
  final List<String> nodeKinds;
  final double confidence, cost, score;
  final ERIRisk risk;
}

class ReconstructionScore {
  const ReconstructionScore({
    required this.simplicity,
    required this.robustness,
    required this.quality,
    required this.maintainability,
    required this.manufacturability,
    required this.inspectability,
    required this.reuse,
  });
  final double simplicity,
      robustness,
      quality,
      maintainability,
      manufacturability,
      inspectability,
      reuse;
  double get total =>
      (simplicity +
          robustness +
          quality +
          maintainability +
          manufacturability +
          inspectability +
          reuse) /
      7;
}

class ERITimelineEntry {
  const ERITimelineEntry(
    this.sequence,
    this.timestamp,
    this.action,
    this.targetId,
    this.actor,
    this.reason,
    this.revision,
  );
  final int sequence, revision;
  final DateTime timestamp;
  final String action, targetId, actor, reason;
}

class ReconstructionAnalytics {
  const ReconstructionAnalytics({
    required this.steps,
    required this.estimatedTime,
    required this.estimatedSavings,
    required this.criticalRegions,
    required this.bottlenecks,
    required this.dependencies,
    required this.averageConfidence,
  });
  final int steps, criticalRegions, bottlenecks, dependencies;
  final Duration estimatedTime, estimatedSavings;
  final double averageConfidence;
}

class EngineeringReconstructionPlan {
  const EngineeringReconstructionPlan({
    required this.id,
    required this.projectId,
    required this.revision,
    required this.nodes,
    required this.strategies,
    required this.selectedStrategyId,
    required this.score,
    required this.timeline,
    required this.analytics,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceFingerprint,
  });
  final String id, projectId, selectedStrategyId, sourceFingerprint;
  final int revision;
  final List<ERIPlanNode> nodes;
  final List<ERIStrategy> strategies;
  final ReconstructionScore score;
  final List<ERITimelineEntry> timeline;
  final ReconstructionAnalytics analytics;
  final DateTime createdAt, updatedAt;
  ERIPlanNode? get nextStep {
    final values = nodes.where((n) => n.status == ERINodeStatus.ready).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return values.firstOrNull;
  }

  EngineeringReconstructionPlan copyWith({
    int? revision,
    List<ERIPlanNode>? nodes,
    String? selectedStrategyId,
    List<ERITimelineEntry>? timeline,
    ReconstructionAnalytics? analytics,
    DateTime? updatedAt,
    String? sourceFingerprint,
  }) => EngineeringReconstructionPlan(
    id: id,
    projectId: projectId,
    revision: revision ?? this.revision,
    nodes: nodes ?? this.nodes,
    strategies: strategies,
    selectedStrategyId: selectedStrategyId ?? this.selectedStrategyId,
    score: score,
    timeline: timeline ?? this.timeline,
    analytics: analytics ?? this.analytics,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
    sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
  );
}

class ERIPlanningInput {
  const ERIPlanningInput(
    this.recognition, {
    this.previous,
    this.changedSourceIds = const [],
  });
  final ProfessionalRecognitionReport recognition;
  final EngineeringReconstructionPlan? previous;
  final List<String> changedSourceIds;
}
