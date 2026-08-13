import '../../geometric_kernel/geometry/vectors.dart';

class Evidence {
  const Evidence({
    required this.id,
    required this.description,
    required this.value,
    required this.source,
    this.unit,
    this.reliability = 1,
  });
  final String id, description, source;
  final double value, reliability;
  final String? unit;
  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'value': value,
    'source': source,
    'unit': unit,
    'reliability': reliability,
  };
}

class ProbabilityScore {
  const ProbabilityScore(this.label, this.probability, this.evidence)
    : assert(probability >= 0 && probability <= 1);
  final String label;
  final double probability;
  final List<Evidence> evidence;
  Map<String, dynamic> toJson() => {
    'label': label,
    'probability': probability,
    'evidence': evidence.map((e) => e.id).toList(),
  };
}

class MeshObservation {
  const MeshObservation({
    required this.meshId,
    required this.vertexCount,
    required this.triangleCount,
    required this.surfaceArea,
    required this.boundingVolume,
    required this.meshDensity,
    required this.boundaryEdgeCount,
    required this.normalCoherence,
    required this.axisExtents,
    required this.centroid,
    required this.evidence,
  });
  final String meshId;
  final int vertexCount, triangleCount, boundaryEdgeCount;
  final double surfaceArea, boundingVolume, meshDensity, normalCoherence;
  final Vector3 axisExtents, centroid;
  final List<Evidence> evidence;
  bool get isWatertight => boundaryEdgeCount == 0;
  Map<String, dynamic> toJson() => {
    'meshId': meshId,
    'vertexCount': vertexCount,
    'triangleCount': triangleCount,
    'surfaceArea': surfaceArea,
    'boundingVolume': boundingVolume,
    'meshDensity': meshDensity,
    'boundaryEdgeCount': boundaryEdgeCount,
    'normalCoherence': normalCoherence,
    'axisExtents': axisExtents.toJson(),
    'centroid': centroid.toJson(),
    'evidence': evidence.map((e) => e.toJson()).toList(),
  };
}

enum HypothesisStatus { proposed, validated, rejected }

class EngineeringHypothesis {
  const EngineeringHypothesis({
    required this.id,
    required this.statement,
    required this.kind,
    required this.confidence,
    required this.evidence,
    this.status = HypothesisStatus.proposed,
    this.alternatives = const [],
  });
  final String id, statement, kind;
  final double confidence;
  final List<Evidence> evidence;
  final HypothesisStatus status;
  final List<String> alternatives;
}

class ReconstructionStep {
  const ReconstructionStep(
    this.order,
    this.operation,
    this.reason,
    this.requiredConfidence,
  );
  final int order;
  final String operation, reason;
  final double requiredConfidence;
}

class ReconstructionPlan {
  const ReconstructionPlan(this.id, this.steps, this.rationale);
  final String id, rationale;
  final List<ReconstructionStep> steps;
}

class ReconstructionStrategy {
  const ReconstructionStrategy(
    this.id,
    this.name,
    this.plan,
    this.expectedConfidence,
    this.cost,
    this.evidence,
  );
  final String id, name;
  final ReconstructionPlan plan;
  final double expectedConfidence, cost;
  final List<Evidence> evidence;
}

class StrategyDecision {
  const StrategyDecision(
    this.selected,
    this.candidates,
    this.explanation,
    this.confidence,
  );
  final ReconstructionStrategy selected;
  final List<ReconstructionStrategy> candidates;
  final String explanation;
  final double confidence;
}

class ValidationAssessment {
  const ValidationAssessment(this.valid, this.score, this.findings);
  final bool valid;
  final double score;
  final List<String> findings;
}

class ReasoningSnapshot {
  const ReasoningSnapshot({
    required this.projectId,
    required this.meshId,
    required this.observation,
    required this.classifications,
    required this.manufacturing,
    required this.hypotheses,
    required this.plan,
    required this.decision,
    required this.validation,
    required this.createdAt,
  });
  final String projectId, meshId;
  final MeshObservation observation;
  final List<ProbabilityScore> classifications, manufacturing;
  final List<EngineeringHypothesis> hypotheses;
  final ReconstructionPlan plan;
  final StrategyDecision decision;
  final ValidationAssessment validation;
  final DateTime createdAt;
}
