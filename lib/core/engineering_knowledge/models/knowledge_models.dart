class KnowledgeProvenance {
  const KnowledgeProvenance(
    this.source,
    this.version, {
    this.reference,
    this.verified = false,
  });
  final String source, version;
  final String? reference;
  final bool verified;
  Map<String, dynamic> toJson() => {
    'source': source,
    'version': version,
    'reference': reference,
    'verified': verified,
  };
}

class KnowledgeConcept {
  const KnowledgeConcept({
    required this.id,
    required this.name,
    required this.kind,
    required this.description,
    required this.attributes,
    required this.provenance,
    this.tags = const [],
  });
  final String id, name, kind, description;
  final Map<String, dynamic> attributes;
  final KnowledgeProvenance provenance;
  final List<String> tags;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'description': description,
    'attributes': attributes,
    'provenance': provenance.toJson(),
    'tags': tags,
  };
}

class KnowledgeRelation {
  const KnowledgeRelation({
    required this.id,
    required this.subject,
    required this.predicate,
    required this.object,
    required this.confidence,
    required this.provenance,
  });
  final String id, subject, predicate, object;
  final double confidence;
  final KnowledgeProvenance provenance;
  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'predicate': predicate,
    'object': object,
    'confidence': confidence,
    'provenance': provenance.toJson(),
  };
}

class KnowledgeEvidence {
  const KnowledgeEvidence(
    this.id,
    this.description,
    this.value,
    this.source, {
    this.reliability = 1,
  });
  final String id, description, source;
  final double value, reliability;
}

class KnowledgeInference {
  const KnowledgeInference({
    required this.conclusion,
    required this.confidence,
    required this.explanation,
    required this.evidence,
    required this.ruleIds,
  });
  final String conclusion, explanation;
  final double confidence;
  final List<KnowledgeEvidence> evidence;
  final List<String> ruleIds;
}

class EngineeringCase {
  const EngineeringCase({
    required this.projectId,
    required this.entityId,
    required this.facts,
    required this.probabilities,
    this.tags = const [],
  });
  final String projectId, entityId;
  final Map<String, dynamic> facts;
  final Map<String, double> probabilities;
  final List<String> tags;
  bool has(String fact) =>
      facts[fact] == true || probabilities.containsKey(fact);
  double probability(String fact) =>
      probabilities[fact] ?? (facts[fact] == true ? 1 : 0);
}
