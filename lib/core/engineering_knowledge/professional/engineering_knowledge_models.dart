enum KnowledgeDomain {
  stamping,
  cutting,
  bending,
  deepDrawing,
  hotforming,
  plasticMolds,
  aerospace,
  fixtures,
  generalTools,
}

enum KnowledgeDecisionKind {
  strategyAccepted,
  strategyRejected,
  referenceAccepted,
  referenceRejected,
}

enum StrategyReuseScope { completePlaybook, selectedSteps }

List<T> _frozen<T>(Iterable<T> values) => List<T>.unmodifiable(values);

class KnowledgeProfile {
  KnowledgeProfile({
    required this.id,
    required this.name,
    required this.domain,
    required this.origin,
    this.version = 1,
    Iterable<String> caseIds = const [],
    Iterable<String> ruleIds = const [],
  }) : caseIds = _frozen(caseIds),
       ruleIds = _frozen(ruleIds);
  final String id, name, origin;
  final KnowledgeDomain domain;
  final int version;
  final List<String> caseIds, ruleIds;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'domain': domain.name,
    'origin': origin,
    'version': version,
    'caseIds': caseIds,
    'ruleIds': ruleIds,
  };
}

class CaseSignature {
  CaseSignature({
    required Iterable<String> dna,
    required Iterable<String> features,
    required Iterable<String> topology,
    required Iterable<String> symmetries,
    required Iterable<String> relations,
    required this.complexity,
    required this.strategy,
  }) : dna = _frozen(dna),
       features = _frozen(features),
       topology = _frozen(topology),
       symmetries = _frozen(symmetries),
       relations = _frozen(relations);
  final List<String> dna, features, topology, symmetries, relations;
  final double complexity;
  final String strategy;
  Map<String, dynamic> toJson() => {
    'dna': dna,
    'features': features,
    'topology': topology,
    'symmetries': symmetries,
    'relations': relations,
    'complexity': complexity,
    'strategy': strategy,
  };
}

class ProfessionalEngineeringCase {
  ProfessionalEngineeringCase({
    required this.id,
    required this.name,
    required this.partType,
    required this.profileId,
    required this.domain,
    required this.userId,
    required this.logicalDate,
    required this.origin,
    required this.signature,
    required this.primitiveGraph,
    required this.featureGraph,
    required this.smartReferences,
    required this.playbook,
    required this.selectedStrategy,
    required Iterable<String> userChanges,
    required this.finalResult,
    this.version = 1,
  }) : userChanges = _frozen(userChanges) {
    if (origin.trim().isEmpty) {
      throw ArgumentError('Every knowledge case requires an origin');
    }
  }
  final String id, name, partType, profileId, userId, logicalDate, origin;
  final KnowledgeDomain domain;
  final CaseSignature signature;
  final Map<String, dynamic> primitiveGraph,
      featureGraph,
      smartReferences,
      playbook;
  final String selectedStrategy, finalResult;
  final List<String> userChanges;
  final int version;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'partType': partType,
    'profileId': profileId,
    'domain': domain.name,
    'userId': userId,
    'logicalDate': logicalDate,
    'origin': origin,
    'signature': signature.toJson(),
    'primitiveGraph': primitiveGraph,
    'featureGraph': featureGraph,
    'smartReferences': smartReferences,
    'playbook': playbook,
    'selectedStrategy': selectedStrategy,
    'userChanges': userChanges,
    'finalResult': finalResult,
    'version': version,
    'geometryModified': false,
  };
}

class SimilarityScore {
  const SimilarityScore({
    required this.caseId,
    required this.dna,
    required this.features,
    required this.topology,
    required this.symmetry,
    required this.relations,
    required this.complexity,
    required this.strategy,
    required this.percentage,
  });
  final String caseId;
  final double dna,
      features,
      topology,
      symmetry,
      relations,
      complexity,
      strategy;
  final double percentage;
  Map<String, dynamic> toJson() => {
    'caseId': caseId,
    'dnaScore': dna,
    'featureScore': features,
    'topologyScore': topology,
    'symmetryScore': symmetry,
    'relationScore': relations,
    'complexityScore': complexity,
    'strategyScore': strategy,
    'percentage': percentage,
  };
}

class KnowledgeDecision {
  const KnowledgeDecision({
    required this.id,
    required this.kind,
    required this.targetId,
    required this.userJustification,
    required this.origin,
    required this.sequence,
    required this.version,
  });
  final String id, targetId, userJustification, origin;
  final KnowledgeDecisionKind kind;
  final int sequence, version;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'targetId': targetId,
    'userJustification': userJustification,
    'origin': origin,
    'sequence': sequence,
    'version': version,
  };
}

class EngineeringKnowledgeRule {
  EngineeringKnowledgeRule({
    required this.id,
    required this.profileId,
    required this.description,
    required Iterable<String> requiredEvidence,
    required this.suggestion,
    required this.origin,
    this.version = 1,
    this.enabled = true,
  }) : requiredEvidence = _frozen(requiredEvidence) {
    if (origin.trim().isEmpty) {
      throw ArgumentError('Every rule requires an origin');
    }
  }
  final String id, profileId, description, suggestion, origin;
  final List<String> requiredEvidence;
  final int version;
  final bool enabled;
  EngineeringKnowledgeRule edit({
    String? description,
    Iterable<String>? requiredEvidence,
    String? suggestion,
    bool? enabled,
  }) => EngineeringKnowledgeRule(
    id: id,
    profileId: profileId,
    description: description ?? this.description,
    requiredEvidence: requiredEvidence ?? this.requiredEvidence,
    suggestion: suggestion ?? this.suggestion,
    origin: origin,
    version: version + 1,
    enabled: enabled ?? this.enabled,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'description': description,
    'requiredEvidence': requiredEvidence,
    'suggestion': suggestion,
    'origin': origin,
    'version': version,
    'enabled': enabled,
  };
}

class KnowledgeRecommendation {
  KnowledgeRecommendation({
    required this.id,
    required this.caseId,
    required this.message,
    required this.justification,
    required Iterable<String> evidence,
  }) : evidence = _frozen(evidence) {
    if (caseId.isEmpty || this.evidence.isEmpty) {
      throw ArgumentError(
        'Recommendation requires an existing case and evidence',
      );
    }
  }
  final String id, caseId, message, justification;
  final List<String> evidence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'caseId': caseId,
    'message': message,
    'justification': justification,
    'evidence': evidence,
    'requiresApproval': true,
  };
}

class StrategyReuseProposal {
  StrategyReuseProposal({
    required this.id,
    required this.sourceCaseId,
    required this.scope,
    required Iterable<String> stepIds,
    required this.justification,
  }) : stepIds = _frozen(stepIds);
  final String id, sourceCaseId, justification;
  final StrategyReuseScope scope;
  final List<String> stepIds;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceCaseId': sourceCaseId,
    'scope': scope.name,
    'stepIds': stepIds,
    'justification': justification,
    'requiresExplicitApproval': true,
    'applied': false,
  };
}

class KnowledgeQuery {
  const KnowledgeQuery({
    this.partType,
    this.feature,
    this.dna,
    this.strategy,
    this.userId,
    this.logicalDate,
    this.domain,
  });
  final String? partType, feature, dna, strategy, userId, logicalDate;
  final KnowledgeDomain? domain;
}

class EngineeringKnowledgeState {
  EngineeringKnowledgeState({
    required Iterable<KnowledgeProfile> profiles,
    required Iterable<ProfessionalEngineeringCase> cases,
    required Iterable<EngineeringKnowledgeRule> rules,
    required Iterable<KnowledgeDecision> decisions,
    required Iterable<SimilarityScore> similarities,
    required Iterable<KnowledgeRecommendation> recommendations,
    required Iterable<StrategyReuseProposal> reuseProposals,
    required this.revision,
  }) : profiles = _frozen(profiles),
       cases = _frozen(cases),
       rules = _frozen(rules),
       decisions = _frozen(decisions),
       similarities = _frozen(similarities),
       recommendations = _frozen(recommendations),
       reuseProposals = _frozen(reuseProposals);
  final List<KnowledgeProfile> profiles;
  final List<ProfessionalEngineeringCase> cases;
  final List<EngineeringKnowledgeRule> rules;
  final List<KnowledgeDecision> decisions;
  final List<SimilarityScore> similarities;
  final List<KnowledgeRecommendation> recommendations;
  final List<StrategyReuseProposal> reuseProposals;
  final int revision;
  Map<String, dynamic> toJson() => {
    'revision': revision,
    'profiles': profiles.map((e) => e.toJson()).toList(),
    'cases': cases.map((e) => e.toJson()).toList(),
    'rules': rules.map((e) => e.toJson()).toList(),
    'decisions': decisions.map((e) => e.toJson()).toList(),
    'similarities': similarities.map((e) => e.toJson()).toList(),
    'recommendations': recommendations.map((e) => e.toJson()).toList(),
    'reuseProposals': reuseProposals.map((e) => e.toJson()).toList(),
    'automaticBehaviorChanges': false,
    'geometryModified': false,
  };
}
