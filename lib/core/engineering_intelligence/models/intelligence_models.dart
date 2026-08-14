import '../../utils/id_generator.dart';

enum IntelligenceAnalysisType {
  project,
  feature,
  reference,
  alignment,
  validation,
  timeline,
  quality,
  dependencies,
  manufacturability,
  modelingStrategy,
}

enum RecommendationType {
  nextOperation,
  bestDatum,
  bestAlignment,
  bestSketch,
  extrudeVsRevolve,
  sweepVsLoft,
  criticalRegions,
  modelingStrategy,
  idealSequence,
  simplification,
  rebuildRisk,
  fragileDependencies,
  dimensionalImprovement,
  machiningPreparation,
  inspectionPreparation,
}

enum RecommendationDecision { pending, accepted, rejected, ignored }

class ProjectKnowledgeSnapshot {
  const ProjectKnowledgeSnapshot({
    required this.projectId,
    this.features = 0,
    this.references = 0,
    this.alignments = 0,
    this.validations = 0,
    this.sketches = 0,
    this.constraints = 0,
    this.profiles = 0,
    this.averageFeatureQuality = 100,
    this.averageReferenceQuality = 100,
    this.averageAlignmentQuality = 100,
    this.averageValidationQuality = 100,
    this.dependencyRisks = 0,
    this.criticalRegions = const [],
    this.metadata = const {},
  });
  final String projectId;
  final int features,
      references,
      alignments,
      validations,
      sketches,
      constraints,
      profiles,
      dependencyRisks;
  final double averageFeatureQuality,
      averageReferenceQuality,
      averageAlignmentQuality,
      averageValidationQuality;
  final List<String> criticalRegions;
  final Map<String, dynamic> metadata;
  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'features': features,
    'references': references,
    'alignments': alignments,
    'validations': validations,
    'sketches': sketches,
    'constraints': constraints,
    'profiles': profiles,
    'averageFeatureQuality': averageFeatureQuality,
    'averageReferenceQuality': averageReferenceQuality,
    'averageAlignmentQuality': averageAlignmentQuality,
    'averageValidationQuality': averageValidationQuality,
    'dependencyRisks': dependencyRisks,
    'criticalRegions': criticalRegions,
    'metadata': metadata,
  };
}

class EngineeringScore {
  const EngineeringScore({
    required this.modelQuality,
    required this.featureQuality,
    required this.referenceQuality,
    required this.alignmentQuality,
    required this.validationQuality,
    required this.manufacturability,
    required this.maintainability,
    required this.editability,
    required this.projectHealth,
    required this.overall,
  });
  final double modelQuality,
      featureQuality,
      referenceQuality,
      alignmentQuality,
      validationQuality,
      manufacturability,
      maintainability,
      editability,
      projectHealth,
      overall;
  Map<String, dynamic> toJson() => {
    'modelQuality': modelQuality,
    'featureQuality': featureQuality,
    'referenceQuality': referenceQuality,
    'alignmentQuality': alignmentQuality,
    'validationQuality': validationQuality,
    'manufacturability': manufacturability,
    'maintainability': maintainability,
    'editability': editability,
    'projectHealth': projectHealth,
    'overall': overall,
  };
}

class EngineeringRecommendation {
  EngineeringRecommendation({
    required this.type,
    required this.title,
    required this.confidence,
    required this.explanation,
    required this.technicalReason,
    required this.advantages,
    required this.disadvantages,
    required this.alternatives,
    required this.expectedImprovement,
    this.affectedFeatures = const [],
    this.affectedReferences = const [],
    this.affectedRegions = const [],
    String? id,
  }) : id = id ?? 'recommendation:${IdGenerator.generate()}',
       createdAt = DateTime.now().toUtc();
  final String id, title, explanation, technicalReason;
  final RecommendationType type;
  final double confidence, expectedImprovement;
  final List<String> advantages,
      disadvantages,
      alternatives,
      affectedFeatures,
      affectedReferences,
      affectedRegions;
  final DateTime createdAt;
  RecommendationDecision decision = RecommendationDecision.pending;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'confidence': confidence,
    'explanation': explanation,
    'technicalReason': technicalReason,
    'advantages': advantages,
    'disadvantages': disadvantages,
    'alternatives': alternatives,
    'expectedImprovement': expectedImprovement,
    'affectedFeatures': affectedFeatures,
    'affectedReferences': affectedReferences,
    'affectedRegions': affectedRegions,
    'createdAt': createdAt.toIso8601String(),
    'decision': decision.name,
  };
}

class EngineeringDiagnostic {
  EngineeringDiagnostic({
    required this.analysisType,
    required this.message,
    required this.severity,
    required this.affectedIds,
    String? id,
  }) : id = id ?? 'diagnostic:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id, message, severity;
  final IntelligenceAnalysisType analysisType;
  final List<String> affectedIds;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'analysisType': analysisType.name,
    'message': message,
    'severity': severity,
    'affectedIds': affectedIds,
    'timestamp': timestamp.toIso8601String(),
  };
}

class EngineeringAnalysis {
  EngineeringAnalysis({
    required this.type,
    required this.snapshot,
    required this.score,
    required this.diagnostics,
    required this.recommendations,
    String? id,
  }) : id = id ?? 'engineering-analysis:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id;
  final IntelligenceAnalysisType type;
  final ProjectKnowledgeSnapshot snapshot;
  final EngineeringScore score;
  final List<EngineeringDiagnostic> diagnostics;
  final List<EngineeringRecommendation> recommendations;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'snapshot': snapshot.toJson(),
    'score': score.toJson(),
    'diagnostics': diagnostics.map((e) => e.toJson()).toList(),
    'recommendations': recommendations.map((e) => e.toJson()).toList(),
    'timestamp': timestamp.toIso8601String(),
  };
}
