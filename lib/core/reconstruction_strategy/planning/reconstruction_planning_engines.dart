import '../../engineering_feature_intelligence/models/engineering_feature_models.dart'
    hide ReconstructionStrategy;
import '../../smart_reference/models/smart_reference_models.dart';
import '../models/reconstruction_strategy_models.dart';

class ReconstructionStepBuilder {
  const ReconstructionStepBuilder();
  List<ReconstructionStep> build(
    String strategyId,
    EngineeringFeatureSession features,
    SmartReferenceSession references,
    StrategyFocus focus,
  ) {
    final entries =
        <
          ({
            String objective,
            String featureId,
            List<String> primitives,
            List<String> references,
            String justification,
          })
        >[];
    final referenceOrder = references.candidates.take(3);
    for (final reference in referenceOrder) {
      entries.add((
        objective: 'Create approved ${reference.type.name}',
        featureId: reference.featureIds.first,
        primitives: reference.primitiveIds,
        references: [reference.id],
        justification:
            '${reference.type.name} establishes reference context before dependent reconstruction.',
      ));
    }
    final orderedFeatures = [...features.hypotheses];
    if (focus == StrategyFocus.productivity) {
      orderedFeatures.sort((a, b) => a.type.index.compareTo(b.type.index));
    } else {
      orderedFeatures.sort((a, b) {
        final score = b.scores.overallConfidence.compareTo(
          a.scores.overallConfidence,
        );
        return score != 0 ? score : a.id.compareTo(b.id);
      });
    }
    for (final feature in orderedFeatures) {
      final related =
          references.candidates
              .where((e) => e.featureIds.contains(feature.id))
              .map((e) => e.id)
              .toList()
            ..sort();
      entries.add((
        objective: 'Reconstruct ${feature.type.name}',
        featureId: feature.id,
        primitives:
            feature.evidence.expand((e) => e.primitiveIds).toSet().toList()
              ..sort(),
        references: related,
        justification:
            '${feature.type.name} follows its approved reference dependencies and confidence-ranked feature evidence.',
      ));
    }
    if (orderedFeatures.isNotEmpty) {
      entries.add((
        objective: 'Validate continuity and critical regions',
        featureId: orderedFeatures.last.id,
        primitives:
            orderedFeatures
                .expand((e) => e.evidence.expand((item) => item.primitiveIds))
                .toSet()
                .toList()
              ..sort(),
        references: references.candidates.map((e) => e.id).toList(),
        justification:
            'Continuity validation follows all proposed reconstruction steps so the complete dependency result can be reviewed.',
      ));
    }
    final steps = <ReconstructionStep>[];
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final previous = index == 0 ? const <String>[] : [steps.last.id];
      steps.add(
        ReconstructionStep(
          id: '$strategyId:step:${index + 1}',
          objective: entry.objective,
          featureId: entry.featureId,
          primitiveIds: entry.primitives,
          referenceIds: entry.references,
          dependencies: previous,
          prerequisites: previous.isEmpty
              ? const ['User approval']
              : ['User approval', 'Completion of ${previous.single}'],
          justification: entry.justification,
          order: index + 1,
          revision: 0,
        ),
      );
    }
    return List.unmodifiable(steps);
  }
}

class DependencyScheduler {
  const DependencyScheduler();
  StrategyDependencyGraph schedule(List<ReconstructionStep> steps) {
    final ids = steps.map((e) => e.id).toSet();
    final dependencies = <StrategyDependency>[];
    for (final step in steps) {
      for (final dependency in step.dependencies) {
        if (!ids.contains(dependency)) {
          throw StateError('Unknown step dependency: $dependency');
        }
        dependencies.add(
          StrategyDependency(
            from: dependency,
            to: step.id,
            reason: '${step.objective} requires $dependency first.',
          ),
        );
      }
    }
    return StrategyDependencyGraph(
      nodes: steps.map((e) => e.id),
      dependencies: dependencies,
    );
  }
}

class EngineeringReasoningEngine {
  const EngineeringReasoningEngine();
  EngineeringReasoning explain(
    List<ReconstructionStep> steps,
    EngineeringFeatureSession features,
    SmartReferenceSession references,
  ) => EngineeringReasoning(
    whyBefore:
        'Reference establishment precedes Features because every Feature step declares reference and predecessor dependencies.',
    whySurfaceFirst:
        'The highest-confidence supporting Feature is scheduled before dependent detail Features.',
    whyMainAxis:
        references.candidates.any(
          (e) => e.type == ReferenceCandidateType.mainAxis,
        )
        ? 'The main axis is the highest-ranked explicit main-axis reference hypothesis.'
        : 'No main-axis hypothesis was selected; axis-dependent steps remain subject to review.',
    discardedHypotheses: <String>{
      ...features.hypotheses.expand((e) => e.discardedHypotheses),
      ...references.candidates.expand((e) => e.discardedHypotheses),
    }.toList()..sort(),
  );
}

class ReconstructionDifficultyPolicy {
  const ReconstructionDifficultyPolicy({
    this.minutesPerStep = 12,
    this.criticalConfidence = .75,
  });
  final int minutesPerStep;
  final double criticalConfidence;
}

class ReconstructionDifficultyEstimator {
  const ReconstructionDifficultyEstimator({
    this.policy = const ReconstructionDifficultyPolicy(),
  });
  final ReconstructionDifficultyPolicy policy;
  ReconstructionDifficulty estimate(
    EngineeringFeatureSession features,
    SmartReferenceSession references,
    int stepCount,
  ) {
    final critical =
        features.hypotheses
            .where(
              (e) => e.scores.overallConfidence < policy.criticalConfidence,
            )
            .map((e) => e.id)
            .toList()
          ..sort();
    final complexity = features.hypotheses.fold<double>(
      0,
      (sum, e) => sum + e.graph.nodes.length,
    );
    final difficulty =
        complexity + critical.length + references.graph.dependencies.length;
    return ReconstructionDifficulty(
      featureCount: features.hypotheses.length,
      estimatedDuration: Duration(minutes: stepCount * policy.minutesPerStep),
      complexity: complexity,
      difficulty: difficulty,
      criticalRegions: critical,
      justification:
          'Policy: ${policy.minutesPerStep} minutes per step; critical confidence below ${policy.criticalConfidence}.',
    );
  }
}

class MultiStrategyPlanner {
  const MultiStrategyPlanner({
    this.stepBuilder = const ReconstructionStepBuilder(),
    this.scheduler = const DependencyScheduler(),
    this.reasoning = const EngineeringReasoningEngine(),
  });
  final ReconstructionStepBuilder stepBuilder;
  final DependencyScheduler scheduler;
  final EngineeringReasoningEngine reasoning;
  List<ReconstructionStrategy> plan(
    String sessionId,
    EngineeringFeatureSession features,
    SmartReferenceSession references,
  ) {
    const configurations = [
      (
        StrategyFocus.maximumPrecision,
        ManufacturingVariant.machining,
        'Strategy A — Maximum Precision',
      ),
      (
        StrategyFocus.productivity,
        ManufacturingVariant.molding,
        'Strategy B — Productivity',
      ),
      (
        StrategyFocus.manufacturingPreparation,
        ManufacturingVariant.stamping,
        'Strategy C — Manufacturing Preparation',
      ),
      (
        StrategyFocus.additiveReadiness,
        ManufacturingVariant.additiveManufacturing,
        'Strategy D — Additive Manufacturing',
      ),
      (
        StrategyFocus.inspectionReadiness,
        ManufacturingVariant.inspection,
        'Strategy E — Inspection',
      ),
    ];
    return List.unmodifiable(
      configurations.asMap().entries.map((entry) {
        final config = entry.value;
        final id = '$sessionId:strategy:${entry.key + 1}';
        final steps = stepBuilder.build(id, features, references, config.$1);
        final evidence = [
          for (final reference in references.candidates)
            ReconstructionEvidence(
              id: '$id:${reference.id}',
              source: 'smartReference',
              description: reference.justification,
              featureIds: reference.featureIds,
              primitiveIds: reference.primitiveIds,
              referenceIds: [reference.id],
              score: reference.scores.overallConfidence,
            ),
        ];
        final confidence =
            evidence.fold<double>(0, (sum, e) => sum + e.score) /
            evidence.length;
        final complexity = steps.length.toDouble();
        return ReconstructionStrategy(
          id: id,
          name: config.$3,
          focus: config.$1,
          manufacturingVariant: config.$2,
          steps: steps,
          graph: scheduler.schedule(steps),
          estimatedDuration: Duration(
            minutes:
                steps.length *
                (config.$1 == StrategyFocus.productivity ? 8 : 12),
          ),
          complexity: complexity,
          risk: 1 - confidence,
          confidence: confidence,
          justification:
              '${config.$3} correlates Primitive Intelligence, Feature graphs and Smart References without executing CAD commands.',
          evidence: evidence,
          reasoning: reasoning.explain(steps, features, references),
        );
      }),
    );
  }
}
