import '../../ai_engineering/models/ai_engineering_models.dart';

enum StrategyFocus {
  maximumPrecision,
  productivity,
  manufacturingPreparation,
  inspectionReadiness,
  additiveReadiness,
}

enum ManufacturingVariant {
  machining,
  molding,
  stamping,
  additiveManufacturing,
  inspection,
}

enum StrategyDecisionType { accepted, edited, rejected }

List<T> _list<T>(Iterable<T> value) => List<T>.unmodifiable(value);

class ReconstructionEvidence {
  ReconstructionEvidence({
    required this.id,
    required this.source,
    required this.description,
    required Iterable<String> featureIds,
    required Iterable<String> primitiveIds,
    required Iterable<String> referenceIds,
    required this.score,
  }) : featureIds = _list(featureIds),
       primitiveIds = _list(primitiveIds),
       referenceIds = _list(referenceIds) {
    if (this.featureIds.isEmpty &&
        this.primitiveIds.isEmpty &&
        this.referenceIds.isEmpty) {
      throw ArgumentError('Reconstruction evidence requires a source entity');
    }
  }
  final String id, source, description;
  final List<String> featureIds, primitiveIds, referenceIds;
  final double score;
  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'description': description,
    'featureIds': featureIds,
    'primitiveIds': primitiveIds,
    'referenceIds': referenceIds,
    'score': score,
  };
}

class ReconstructionStep {
  ReconstructionStep({
    required this.id,
    required this.objective,
    required this.featureId,
    required Iterable<String> primitiveIds,
    required Iterable<String> referenceIds,
    required Iterable<String> dependencies,
    required Iterable<String> prerequisites,
    required this.justification,
    required this.order,
    required this.revision,
  }) : primitiveIds = _list(primitiveIds),
       referenceIds = _list(referenceIds),
       dependencies = _list(dependencies),
       prerequisites = _list(prerequisites) {
    if (justification.trim().isEmpty) {
      throw ArgumentError.value(
        justification,
        'justification',
        'must not be empty',
      );
    }
  }
  final String id, objective, featureId, justification;
  final List<String> primitiveIds, referenceIds, dependencies, prerequisites;
  final int order, revision;
  ReconstructionStep edit({
    String? objective,
    String? justification,
    Iterable<String>? prerequisites,
  }) => ReconstructionStep(
    id: id,
    objective: objective ?? this.objective,
    featureId: featureId,
    primitiveIds: primitiveIds,
    referenceIds: referenceIds,
    dependencies: dependencies,
    prerequisites: prerequisites ?? this.prerequisites,
    justification: justification ?? this.justification,
    order: order,
    revision: revision + 1,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'objective': objective,
    'featureId': featureId,
    'primitiveIds': primitiveIds,
    'referenceIds': referenceIds,
    'dependencies': dependencies,
    'prerequisites': prerequisites,
    'justification': justification,
    'order': order,
    'revision': revision,
    'executed': false,
  };
}

class StrategyDependency {
  const StrategyDependency({
    required this.from,
    required this.to,
    required this.reason,
  });
  final String from, to, reason;
  Map<String, dynamic> toJson() => {'from': from, 'to': to, 'reason': reason};
}

class StrategyDependencyGraph {
  StrategyDependencyGraph({
    required Iterable<String> nodes,
    required Iterable<StrategyDependency> dependencies,
  }) : nodes = _list(nodes),
       dependencies = _list(dependencies) {
    final ids = this.nodes.toSet();
    if (ids.length != this.nodes.length) {
      throw ArgumentError('Strategy graph nodes must be unique');
    }
    if (this.dependencies.any(
      (e) => !ids.contains(e.from) || !ids.contains(e.to),
    )) {
      throw ArgumentError('Strategy dependency has unknown endpoint');
    }
    if (_hasCycle(ids, this.dependencies)) {
      throw ArgumentError('Strategy dependency graph must be acyclic');
    }
  }
  final List<String> nodes;
  final List<StrategyDependency> dependencies;
  static bool _hasCycle(Set<String> ids, List<StrategyDependency> edges) {
    final outgoing = {for (final id in ids) id: <String>[]};
    for (final edge in edges) {
      outgoing[edge.from]!.add(edge.to);
    }
    final active = <String>{}, complete = <String>{};
    bool visit(String id) {
      if (active.contains(id)) {
        return true;
      }
      if (complete.contains(id)) {
        return false;
      }
      active.add(id);
      for (final next in outgoing[id]!) {
        if (visit(next)) {
          return true;
        }
      }
      active.remove(id);
      complete.add(id);
      return false;
    }

    return ids.any(visit);
  }

  Map<String, dynamic> toJson() => {
    'nodes': nodes,
    'dependencies': dependencies.map((e) => e.toJson()).toList(),
    'acyclic': true,
  };
}

class ReconstructionDifficulty {
  ReconstructionDifficulty({
    required this.featureCount,
    required this.estimatedDuration,
    required this.complexity,
    required this.difficulty,
    required Iterable<String> criticalRegions,
    required this.justification,
  }) : criticalRegions = _list(criticalRegions);
  final int featureCount;
  final Duration estimatedDuration;
  final double complexity, difficulty;
  final List<String> criticalRegions;
  final String justification;
  Map<String, dynamic> toJson() => {
    'featureCount': featureCount,
    'estimatedMinutes': estimatedDuration.inMinutes,
    'complexity': complexity,
    'difficulty': difficulty,
    'criticalRegions': criticalRegions,
    'justification': justification,
  };
}

class EngineeringReasoning {
  EngineeringReasoning({
    required this.whyBefore,
    required this.whySurfaceFirst,
    required this.whyMainAxis,
    required Iterable<String> discardedHypotheses,
  }) : discardedHypotheses = _list(discardedHypotheses);
  final String whyBefore, whySurfaceFirst, whyMainAxis;
  final List<String> discardedHypotheses;
  Map<String, dynamic> toJson() => {
    'whyBefore': whyBefore,
    'whySurfaceFirst': whySurfaceFirst,
    'whyMainAxis': whyMainAxis,
    'discardedHypotheses': discardedHypotheses,
  };
}

class ReconstructionStrategy {
  ReconstructionStrategy({
    required this.id,
    required this.name,
    required this.focus,
    required this.manufacturingVariant,
    required Iterable<ReconstructionStep> steps,
    required this.graph,
    required this.estimatedDuration,
    required this.complexity,
    required this.risk,
    required this.confidence,
    required this.justification,
    required Iterable<ReconstructionEvidence> evidence,
    required this.reasoning,
  }) : steps = _list(steps),
       evidence = _list(evidence) {
    if (this.steps.isEmpty || this.evidence.isEmpty) {
      throw ArgumentError('Strategy requires steps and evidence');
    }
  }
  final String id, name, justification;
  final StrategyFocus focus;
  final ManufacturingVariant manufacturingVariant;
  final List<ReconstructionStep> steps;
  final StrategyDependencyGraph graph;
  final Duration estimatedDuration;
  final double complexity, risk, confidence;
  final List<ReconstructionEvidence> evidence;
  final EngineeringReasoning reasoning;
  ReconstructionStrategy replaceStep(
    ReconstructionStep step,
    StrategyDependencyGraph updatedGraph,
  ) => ReconstructionStrategy(
    id: id,
    name: name,
    focus: focus,
    manufacturingVariant: manufacturingVariant,
    steps: [
      for (final current in steps) current.id == step.id ? step : current,
    ],
    graph: updatedGraph,
    estimatedDuration: estimatedDuration,
    complexity: complexity,
    risk: risk,
    confidence: confidence,
    justification: justification,
    evidence: evidence,
    reasoning: reasoning,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'focus': focus.name,
    'manufacturingVariant': manufacturingVariant.name,
    'steps': steps.map((e) => e.toJson()).toList(),
    'graph': graph.toJson(),
    'estimatedMinutes': estimatedDuration.inMinutes,
    'complexity': complexity,
    'risk': risk,
    'confidence': confidence,
    'justification': justification,
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'reasoning': reasoning.toJson(),
    'consultative': true,
    'commandsExecuted': false,
    'geometryModified': false,
  };
}

class EngineeringPlaybook {
  EngineeringPlaybook({
    required this.id,
    required this.partProfile,
    required this.recommendedStrategyId,
    required Iterable<ReconstructionStep> steps,
    required this.justification,
    required this.auditVersion,
  }) : steps = _list(steps);
  final String id, partProfile, recommendedStrategyId, justification;
  final List<ReconstructionStep> steps;
  final int auditVersion;
  EngineeringPlaybook replaceStep(ReconstructionStep step) =>
      EngineeringPlaybook(
        id: id,
        partProfile: partProfile,
        recommendedStrategyId: recommendedStrategyId,
        steps: [
          for (final current in steps) current.id == step.id ? step : current,
        ],
        justification: justification,
        auditVersion: auditVersion + 1,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'partProfile': partProfile,
    'recommendedStrategyId': recommendedStrategyId,
    'steps': steps.map((e) => e.toJson()).toList(),
    'justification': justification,
    'auditVersion': auditVersion,
    'executed': false,
  };
}

class StrategyDecision {
  const StrategyDecision({
    required this.strategyId,
    required this.type,
    required this.reason,
    required this.sequence,
    this.stepId,
  });
  final String strategyId, reason;
  final StrategyDecisionType type;
  final int sequence;
  final String? stepId;
  Map<String, dynamic> toJson() => {
    'strategyId': strategyId,
    'type': type.name,
    'reason': reason,
    'sequence': sequence,
    'stepId': stepId,
  };
}

class ReconstructionStrategySession {
  ReconstructionStrategySession({
    required this.id,
    required this.context,
    required Iterable<ReconstructionStrategy> strategies,
    required this.playbook,
    required this.difficulty,
    required Iterable<StrategyDecision> decisions,
  }) : strategies = _list(strategies),
       decisions = _list(decisions);
  final String id;
  final EngineeringContextSnapshot context;
  final List<ReconstructionStrategy> strategies;
  final EngineeringPlaybook playbook;
  final ReconstructionDifficulty difficulty;
  final List<StrategyDecision> decisions;
  ReconstructionStrategySession copyWith({
    Iterable<ReconstructionStrategy>? strategies,
    EngineeringPlaybook? playbook,
    Iterable<StrategyDecision>? decisions,
  }) => ReconstructionStrategySession(
    id: id,
    context: context,
    strategies: strategies ?? this.strategies,
    playbook: playbook ?? this.playbook,
    difficulty: difficulty,
    decisions: decisions ?? this.decisions,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'context': context.toJson(),
    'strategies': strategies.map((e) => e.toJson()).toList(),
    'playbook': playbook.toJson(),
    'difficulty': difficulty.toJson(),
    'decisions': decisions.map((e) => e.toJson()).toList(),
    'automaticCommands': false,
    'geometryModified': false,
  };
}
