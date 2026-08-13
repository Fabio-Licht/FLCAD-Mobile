import '../models/knowledge_models.dart';

enum FactOperator { exists, equals, greaterOrEqual, probabilityAtLeast }

class RuleCondition {
  const RuleCondition(this.fact, this.operator, {this.value, this.threshold});
  final String fact;
  final FactOperator operator;
  final Object? value;
  final double? threshold;
  bool matches(EngineeringCase c) => switch (operator) {
    FactOperator.exists => c.has(fact),
    FactOperator.equals => c.facts[fact] == value,
    FactOperator.greaterOrEqual =>
      c.facts[fact] is num &&
          (c.facts[fact] as num).toDouble() >= (value as num).toDouble(),
    FactOperator.probabilityAtLeast => c.probability(fact) >= (threshold ?? 0),
  };
  double support(EngineeringCase c) =>
      operator == FactOperator.probabilityAtLeast
      ? c.probability(fact)
      : (matches(c) ? 1 : 0);
}

class EngineeringRule {
  const EngineeringRule({
    required this.id,
    required this.description,
    required this.conditions,
    required this.conclusion,
    required this.baseConfidence,
    required this.provenance,
  });
  final String id, description, conclusion;
  final List<RuleCondition> conditions;
  final double baseConfidence;
  final KnowledgeProvenance provenance;
  KnowledgeInference? evaluate(EngineeringCase c) {
    if (!conditions.every((condition) => condition.matches(c))) return null;
    final support = conditions.map((v) => v.support(c)).reduce((a, b) => a * b),
        evidence = conditions
            .map(
              (v) => KnowledgeEvidence(
                '$id:${v.fact}',
                'Satisfied ${v.operator.name} condition',
                v.support(c),
                'engineering.case',
              ),
            )
            .toList();
    return KnowledgeInference(
      conclusion: conclusion,
      confidence: (baseConfidence * support).clamp(0, 1),
      explanation:
          '$description. All ${conditions.length} conditions were satisfied.',
      evidence: evidence,
      ruleIds: [id],
    );
  }
}

class EngineeringRulesEngine {
  EngineeringRulesEngine(Iterable<EngineeringRule> rules)
    : rules = List.unmodifiable(rules);
  final List<EngineeringRule> rules;
  List<KnowledgeInference> infer(EngineeringCase c) =>
      rules.map((r) => r.evaluate(c)).whereType<KnowledgeInference>().toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
}

class CoreEngineeringRules {
  static const p = KnowledgeProvenance(
    'FLCAD Engineering Rules',
    '0.7.0',
    verified: true,
  );
  static EngineeringRulesEngine create() => EngineeringRulesEngine(const [
    EngineeringRule(
      id: 'rule.thread.requiresDiameter',
      description: 'A threaded hole requires a nominal diameter',
      conditions: [
        RuleCondition('feature.hole', FactOperator.exists),
        RuleCondition('feature.thread', FactOperator.exists),
      ],
      conclusion: 'requirement.nominalDiameter',
      baseConfidence: 1,
      provenance: p,
    ),
    EngineeringRule(
      id: 'rule.pocket.hasBottom',
      description: 'A pocket normally terminates at a bottom surface',
      conditions: [
        RuleCondition(
          'feature.pocket',
          FactOperator.probabilityAtLeast,
          threshold: .5,
        ),
      ],
      conclusion: 'surface.bottom',
      baseConfidence: .9,
      provenance: p,
    ),
    EngineeringRule(
      id: 'rule.casting.needsDraftReview',
      description: 'Cast or molded geometry requires draft review',
      conditions: [
        RuleCondition(
          'process.casting',
          FactOperator.probabilityAtLeast,
          threshold: .45,
        ),
      ],
      conclusion: 'review.draft',
      baseConfidence: .95,
      provenance: p,
    ),
    EngineeringRule(
      id: 'rule.bearingSeat',
      description:
          'An axial cylinder with a fillet and precision evidence is consistent with a bearing seat',
      conditions: [
        RuleCondition(
          'surface.cylinder',
          FactOperator.probabilityAtLeast,
          threshold: .55,
        ),
        RuleCondition('feature.fillet', FactOperator.exists),
        RuleCondition('inspection.tolerance', FactOperator.exists),
        RuleCondition('alignment.mainAxis', FactOperator.exists),
      ],
      conclusion: 'feature.bearingSeat',
      baseConfidence: .92,
      provenance: p,
    ),
  ]);
}
