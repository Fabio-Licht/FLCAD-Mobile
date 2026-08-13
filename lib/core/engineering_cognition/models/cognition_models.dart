import '../../engineering_knowledge/models/knowledge_models.dart';

class CognitionEvidence {
  const CognitionEvidence(
    this.id,
    this.description,
    this.value,
    this.source, {
    this.reliability = 1,
  });
  final String id, description, source;
  final double value, reliability;
  KnowledgeEvidence toKnowledge() => KnowledgeEvidence(
    id,
    description,
    value,
    source,
    reliability: reliability,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'value': value,
    'source': source,
    'reliability': reliability,
  };
}

class PrimitiveRecognition {
  const PrimitiveRecognition({
    required this.kind,
    required this.confidence,
    required this.evidence,
    required this.regionId,
    required this.provenance,
    this.discardedAlternatives = const [],
  });
  final String kind, regionId, provenance;
  final double confidence;
  final List<CognitionEvidence> evidence;
  final List<String> discardedAlternatives;
}

class RecognizedFeature {
  const RecognizedFeature({
    required this.id,
    required this.kind,
    required this.confidence,
    required this.evidence,
    required this.provenance,
    required this.regionIds,
    required this.relatedFeatureIds,
    required this.knowledgeRuleIds,
    required this.explanation,
    required this.discardedAlternatives,
  });
  final String id, kind, provenance, explanation;
  final double confidence;
  final List<CognitionEvidence> evidence;
  final List<String> regionIds,
      relatedFeatureIds,
      knowledgeRuleIds,
      discardedAlternatives;
}

class EngineeringIntent {
  const EngineeringIntent(
    this.function,
    this.confidence,
    this.explanation,
    this.featureIds,
    this.evidence,
  );
  final String function, explanation;
  final double confidence;
  final List<String> featureIds;
  final List<CognitionEvidence> evidence;
}

class PartClassification {
  const PartClassification(this.kind, this.probability, this.evidence);
  final String kind;
  final double probability;
  final List<CognitionEvidence> evidence;
}

enum SuggestionKind { reference, surface, sketch, feature }

class CognitionSuggestion {
  const CognitionSuggestion(
    this.id,
    this.kind,
    this.recommendation,
    this.order,
    this.confidence,
    this.reason,
    this.sourceIds,
  );
  final String id, recommendation, reason;
  final SuggestionKind kind;
  final int order;
  final double confidence;
  final List<String> sourceIds;
}

class ManufacturingAssessment {
  const ManufacturingAssessment(
    this.featureId,
    this.process,
    this.toolFamily,
    this.confidence,
    this.expectedToleranceSource,
    this.explanation,
  );
  final String featureId,
      process,
      toolFamily,
      expectedToleranceSource,
      explanation;
  final double confidence;
}

class InspectionAssessment {
  const InspectionAssessment(
    this.targetId,
    this.role,
    this.confidence,
    this.reason,
  );
  final String targetId, role, reason;
  final double confidence;
}

class CognitionSnapshot {
  const CognitionSnapshot({
    required this.projectId,
    required this.meshId,
    required this.primitives,
    required this.features,
    required this.intents,
    required this.partClassifications,
    required this.references,
    required this.surfaces,
    required this.reconstruction,
    required this.manufacturing,
    required this.inspection,
    required this.createdAt,
  });
  final String projectId, meshId;
  final List<PrimitiveRecognition> primitives;
  final List<RecognizedFeature> features;
  final List<EngineeringIntent> intents;
  final List<PartClassification> partClassifications;
  final List<CognitionSuggestion> references, surfaces, reconstruction;
  final List<ManufacturingAssessment> manufacturing;
  final List<InspectionAssessment> inspection;
  final DateTime createdAt;
}
