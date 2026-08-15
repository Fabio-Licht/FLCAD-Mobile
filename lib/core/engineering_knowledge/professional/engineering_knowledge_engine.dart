import 'engineering_knowledge_models.dart';

class EngineeringSimilarityEngine {
  const EngineeringSimilarityEngine();
  double _jaccard(List<String> a, List<String> b) {
    final left = a.toSet(), right = b.toSet();
    if (left.isEmpty && right.isEmpty) {
      return 1;
    }
    return left.intersection(right).length / left.union(right).length;
  }

  SimilarityScore compare(
    CaseSignature query,
    ProfessionalEngineeringCase item,
  ) {
    final target = item.signature;
    final dna = _jaccard(query.dna, target.dna);
    final features = _jaccard(query.features, target.features);
    final topology = _jaccard(query.topology, target.topology);
    final symmetry = _jaccard(query.symmetries, target.symmetries);
    final relations = _jaccard(query.relations, target.relations);
    final complexity = (1 - (query.complexity - target.complexity).abs())
        .clamp(0, 1)
        .toDouble();
    final strategy = query.strategy == target.strategy ? 1.0 : 0.0;
    final percentage =
        (dna +
            features +
            topology +
            symmetry +
            relations +
            complexity +
            strategy) /
        7 *
        100;
    return SimilarityScore(
      caseId: item.id,
      dna: dna,
      features: features,
      topology: topology,
      symmetry: symmetry,
      relations: relations,
      complexity: complexity,
      strategy: strategy,
      percentage: percentage,
    );
  }

  List<SimilarityScore> rank(
    CaseSignature query,
    Iterable<ProfessionalEngineeringCase> cases,
  ) {
    final result = cases.map((e) => compare(query, e)).toList();
    result.sort((a, b) {
      final score = b.percentage.compareTo(a.percentage);
      return score != 0 ? score : a.caseId.compareTo(b.caseId);
    });
    return List.unmodifiable(result);
  }
}

class EngineeringKnowledgeEngine {
  EngineeringKnowledgeEngine({EngineeringSimilarityEngine? similarityEngine})
    : _similarity = similarityEngine ?? const EngineeringSimilarityEngine(),
      _state = EngineeringKnowledgeState(
        profiles: defaultProfiles,
        cases: const [],
        rules: const [],
        decisions: const [],
        similarities: const [],
        recommendations: const [],
        reuseProposals: const [],
        revision: 0,
      ) {
    _history.add(_state);
  }
  final EngineeringSimilarityEngine _similarity;
  EngineeringKnowledgeState _state;
  final List<EngineeringKnowledgeState> _history = [];
  EngineeringKnowledgeState get state => _state;

  static final List<KnowledgeProfile> defaultProfiles = List.unmodifiable([
    for (final domain in KnowledgeDomain.values)
      KnowledgeProfile(
        id: 'profile-${domain.name}',
        name: _profileName(domain),
        domain: domain,
        origin: 'G-012G built-in profile catalog',
      ),
  ]);
  static String _profileName(KnowledgeDomain domain) => switch (domain) {
    KnowledgeDomain.stamping => 'Estampos',
    KnowledgeDomain.cutting => 'Corte',
    KnowledgeDomain.bending => 'Dobra',
    KnowledgeDomain.deepDrawing => 'Repuxo',
    KnowledgeDomain.hotforming => 'Hotforming',
    KnowledgeDomain.plasticMolds => 'Moldes Plásticos',
    KnowledgeDomain.aerospace => 'Aeroespacial',
    KnowledgeDomain.fixtures => 'Dispositivos',
    KnowledgeDomain.generalTools => 'Ferramentas Gerais',
  };

  void _commit({
    List<KnowledgeProfile>? profiles,
    List<ProfessionalEngineeringCase>? cases,
    List<EngineeringKnowledgeRule>? rules,
    List<KnowledgeDecision>? decisions,
    List<SimilarityScore>? similarities,
    List<KnowledgeRecommendation>? recommendations,
    List<StrategyReuseProposal>? reuseProposals,
  }) {
    _state = EngineeringKnowledgeState(
      profiles: profiles ?? _state.profiles,
      cases: cases ?? _state.cases,
      rules: rules ?? _state.rules,
      decisions: decisions ?? _state.decisions,
      similarities: similarities ?? _state.similarities,
      recommendations: recommendations ?? _state.recommendations,
      reuseProposals: reuseProposals ?? _state.reuseProposals,
      revision: _state.revision + 1,
    );
    _history.add(_state);
  }

  void registerCase(ProfessionalEngineeringCase item) {
    if (_state.cases.any((e) => e.id == item.id)) {
      throw StateError('Duplicate engineering case: ${item.id}');
    }
    if (!_state.profiles.any((e) => e.id == item.profileId)) {
      throw StateError('Unknown knowledge profile: ${item.profileId}');
    }
    _commit(cases: [..._state.cases, item]);
  }

  List<SimilarityScore> findSimilar(CaseSignature signature) {
    final ranked = _similarity.rank(signature, _state.cases);
    _commit(similarities: ranked);
    return ranked;
  }

  void recordDecision(KnowledgeDecision decision) {
    if (decision.origin.trim().isEmpty ||
        decision.userJustification.trim().isEmpty) {
      throw ArgumentError('Decision requires origin and user justification');
    }
    _commit(decisions: [..._state.decisions, decision]);
  }

  void addRule(EngineeringKnowledgeRule rule) {
    if (_state.rules.any((e) => e.id == rule.id)) {
      throw StateError('Duplicate knowledge rule: ${rule.id}');
    }
    _commit(rules: [..._state.rules, rule]);
  }

  void editRule(
    String id, {
    String? description,
    Iterable<String>? requiredEvidence,
    String? suggestion,
    bool? enabled,
  }) {
    if (!_state.rules.any((e) => e.id == id)) {
      throw StateError('Unknown knowledge rule: $id');
    }
    _commit(
      rules: [
        for (final rule in _state.rules)
          if (rule.id == id)
            rule.edit(
              description: description,
              requiredEvidence: requiredEvidence,
              suggestion: suggestion,
              enabled: enabled,
            )
          else
            rule,
      ],
    );
  }

  List<EngineeringKnowledgeRule> evaluateRules(
    String profileId,
    Iterable<String> evidence,
  ) {
    final values = evidence.toSet();
    return List.unmodifiable(
      _state.rules.where(
        (rule) =>
            rule.enabled &&
            rule.profileId == profileId &&
            rule.requiredEvidence.every(values.contains),
      ),
    );
  }

  KnowledgeRecommendation recommendFromCase(
    String caseId,
    String message,
    String justification,
  ) {
    final item = _state.cases.where((e) => e.id == caseId).firstOrNull;
    if (item == null) {
      throw StateError(
        'Recommendation must reference an existing case: $caseId',
      );
    }
    final recommendation = KnowledgeRecommendation(
      id: 'recommendation-${_state.revision + 1}-$caseId',
      caseId: caseId,
      message: message,
      justification: justification,
      evidence: [
        'case:$caseId',
        'result:${item.finalResult}',
        'strategy:${item.selectedStrategy}',
      ],
    );
    _commit(recommendations: [..._state.recommendations, recommendation]);
    return recommendation;
  }

  StrategyReuseProposal proposeReuse(
    String caseId,
    StrategyReuseScope scope, {
    Iterable<String> stepIds = const [],
  }) {
    final item = _state.cases.where((e) => e.id == caseId).firstOrNull;
    if (item == null) {
      throw StateError('Reuse must reference an existing case: $caseId');
    }
    final steps = stepIds.toList();
    if (scope == StrategyReuseScope.selectedSteps && steps.isEmpty) {
      throw ArgumentError('Partial reuse requires selected steps');
    }
    final proposal = StrategyReuseProposal(
      id: 'reuse-${_state.revision + 1}-$caseId',
      sourceCaseId: caseId,
      scope: scope,
      stepIds: steps,
      justification:
          'Reuse is based on approved case $caseId and requires explicit user approval.',
    );
    _commit(reuseProposals: [..._state.reuseProposals, proposal]);
    return proposal;
  }

  List<ProfessionalEngineeringCase> search(KnowledgeQuery query) =>
      List.unmodifiable(
        _state.cases.where((item) {
          bool contains(Iterable<String> values, String? value) =>
              value == null ||
              values.any((e) => e.toLowerCase().contains(value.toLowerCase()));
          return (query.partType == null || item.partType == query.partType) &&
              contains(item.signature.features, query.feature) &&
              contains(item.signature.dna, query.dna) &&
              (query.strategy == null ||
                  item.selectedStrategy == query.strategy) &&
              (query.userId == null || item.userId == query.userId) &&
              (query.logicalDate == null ||
                  item.logicalDate == query.logicalDate) &&
              (query.domain == null || item.domain == query.domain);
        }),
      );

  EngineeringKnowledgeState rollback(int revision) {
    final match = _history.where((e) => e.revision == revision).firstOrNull;
    if (match == null) {
      throw RangeError('Unknown knowledge revision: $revision');
    }
    _state = match;
    _history.add(match);
    return _state;
  }
}
