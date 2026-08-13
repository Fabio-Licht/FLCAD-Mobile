enum EngineeringDecisionType {
  reference,
  sketch,
  surface,
  feature,
  strategy,
  validation,
  workflow,
}

enum DecisionOrigin {
  user,
  arei,
  engineeringDna,
  cognition,
  autonomous,
  workflow,
  plugin,
}

enum DecisionPriority { low, normal, high, critical }

enum DecisionRisk { low, medium, high, critical }

enum DecisionStatus {
  proposed,
  accepted,
  rejected,
  deferred,
  replaced,
  modified,
}

enum DecisionPolicy {
  precision,
  speed,
  simplicity,
  manufacturing,
  inspection,
  meshPreservation,
}

class DecisionEvidence {
  const DecisionEvidence({
    required this.id,
    required this.description,
    required this.source,
    required this.value,
    this.ruleIds = const [],
  });
  final String id, description, source;
  final double value;
  final List<String> ruleIds;
}

class DecisionCriteria {
  const DecisionCriteria({
    required this.recognitionConfidence,
    required this.meshQuality,
    required this.captureCompleteness,
    required this.computationalCost,
    required this.reconstructionImpact,
    required this.referenceReuse,
    required this.partComplexity,
    required this.engineeringIntent,
    required this.successHistory,
  });
  final double recognitionConfidence,
      meshQuality,
      captureCompleteness,
      computationalCost,
      reconstructionImpact,
      referenceReuse,
      partComplexity,
      engineeringIntent,
      successHistory;
}

class DecisionScore {
  const DecisionScore(this.value, this.components, this.policy);
  final double value;
  final Map<String, double> components;
  final DecisionPolicy policy;
}

class DecisionAlternative {
  const DecisionAlternative({
    required this.id,
    required this.name,
    required this.kind,
    required this.estimatedTime,
    required this.confidence,
    required this.complexity,
    required this.risk,
    required this.score,
  });
  final String id, name, kind;
  final Duration estimatedTime;
  final double confidence, complexity;
  final DecisionRisk risk;
  final double score;
}

class EngineeringDecision {
  const EngineeringDecision({
    required this.id,
    required this.projectId,
    required this.type,
    required this.origin,
    required this.title,
    required this.evidence,
    required this.confidence,
    required this.priority,
    required this.impact,
    required this.dependencies,
    required this.alternatives,
    required this.estimatedCost,
    required this.expectedBenefit,
    required this.risk,
    required this.justification,
    required this.timestamp,
    required this.responsible,
    required this.score,
    this.status = DecisionStatus.proposed,
    this.regionId,
    this.revision = 1,
    this.replacesDecisionId,
  });
  final String id, projectId, title, impact, justification, responsible;
  final EngineeringDecisionType type;
  final DecisionOrigin origin;
  final List<DecisionEvidence> evidence;
  final double confidence, estimatedCost, expectedBenefit;
  final DecisionPriority priority;
  final List<String> dependencies;
  final List<DecisionAlternative> alternatives;
  final DecisionRisk risk;
  final DateTime timestamp;
  final DecisionScore score;
  final DecisionStatus status;
  final String? regionId, replacesDecisionId;
  final int revision;
  EngineeringDecision copyWith({
    DecisionStatus? status,
    String? title,
    DecisionPriority? priority,
    int? revision,
    String? replacesDecisionId,
  }) => EngineeringDecision(
    id: id,
    projectId: projectId,
    type: type,
    origin: origin,
    title: title ?? this.title,
    evidence: evidence,
    confidence: confidence,
    priority: priority ?? this.priority,
    impact: impact,
    dependencies: dependencies,
    alternatives: alternatives,
    estimatedCost: estimatedCost,
    expectedBenefit: expectedBenefit,
    risk: risk,
    justification: justification,
    timestamp: timestamp,
    responsible: responsible,
    score: score,
    status: status ?? this.status,
    regionId: regionId,
    revision: revision ?? this.revision,
    replacesDecisionId: replacesDecisionId ?? this.replacesDecisionId,
  );
}

class EngineeringGoal {
  const EngineeringGoal({
    required this.id,
    required this.projectId,
    required this.title,
    this.parentId,
    this.prerequisiteIds = const [],
    this.completionCriteria = const [],
    this.completed = false,
  });
  final String id, projectId, title;
  final String? parentId;
  final List<String> prerequisiteIds, completionCriteria;
  final bool completed;
}

class DecisionSimulationResult {
  const DecisionSimulationResult({
    required this.decisionId,
    required this.alternativeId,
    required this.projectedScore,
    required this.projectedCost,
    required this.projectedRisk,
    required this.impact,
    required this.changedDecisionIds,
  });
  final String decisionId, alternativeId, impact;
  final double projectedScore, projectedCost;
  final DecisionRisk projectedRisk;
  final List<String> changedDecisionIds;
}

class DecisionTimelineEntry {
  const DecisionTimelineEntry({
    required this.sequence,
    required this.decisionId,
    required this.action,
    required this.timestamp,
    required this.actor,
    required this.reason,
    required this.revision,
  });
  final int sequence, revision;
  final String decisionId, action, actor, reason;
  final DateTime timestamp;
}

class DecisionAnalytics {
  const DecisionAnalytics({
    required this.automatic,
    required this.manual,
    required this.estimatedTimeSaved,
    required this.reworkAvoided,
    required this.acceptanceRate,
    required this.correctionRate,
    required this.averageConfidence,
  });
  final int automatic, manual, reworkAvoided;
  final Duration estimatedTimeSaved;
  final double acceptanceRate, correctionRate, averageConfidence;
}

class DecisionRequest {
  const DecisionRequest({
    required this.projectId,
    required this.type,
    required this.origin,
    required this.title,
    required this.criteria,
    required this.evidence,
    required this.impact,
    this.dependencies = const [],
    this.regionId,
    this.responsible = 'FLCAD EDE',
  });
  final String projectId, title, impact, responsible;
  final EngineeringDecisionType type;
  final DecisionOrigin origin;
  final DecisionCriteria criteria;
  final List<DecisionEvidence> evidence;
  final List<String> dependencies;
  final String? regionId;
}
