import '../../engineering_cognition/models/cognition_models.dart';
import '../dependencies/dependency_graph.dart';
import '../models/reconstruction_models.dart';
import '../strategy/autonomous_strategy_engine.dart';

class ReconstructionMasterPlanner {
  const ReconstructionMasterPlanner({
    this.strategies = const AutonomousStrategyEngine(),
  });
  final AutonomousStrategyEngine strategies;
  ReconstructionWorkflow build(ReconstructionPlanInput input) {
    final c = input.cognition,
        strategy = strategies.select(c),
        alternatives = strategies
            .candidates(c)
            .where((s) => s.id != strategy.id)
            .map((s) => s.id)
            .toList(),
        stages = <ReconstructionStage>[];
    ReconstructionDecision decision(
      double confidence,
      String reason,
      List<String> sources, {
      ReconstructionRisk risk = ReconstructionRisk.low,
    }) => ReconstructionDecision(
      confidence: confidence,
      risk: risk,
      evidence: sources
          .map(
            (s) => ReconstructionEvidence(
              'source:$s',
              'Cognition source supporting this stage',
              confidence,
              'Engineering Cognition',
            ),
          )
          .toList(),
      alternatives: alternatives,
      impact: 'Changes may invalidate dependent stages.',
      explanation: reason,
    );
    stages.add(
      ReconstructionStage(
        id: 'project:${c.projectId}',
        type: ReconstructionStageType.project,
        name: 'Project ${c.projectId}',
        order: 1,
        priority: 100,
        dependencies: const [],
        sourceIds: [c.projectId],
        decision: decision(1, 'Project First root of the workflow.', [
          c.projectId,
        ]),
      ),
    );
    stages.add(
      ReconstructionStage(
        id: 'mesh:${c.meshId}',
        type: ReconstructionStageType.mesh,
        name: 'Observed mesh',
        order: 2,
        priority: 95,
        dependencies: ['project:${c.projectId}'],
        sourceIds: [c.meshId],
        decision: decision(
          .95,
          'AREI and Cognition observations originate from this mesh.',
          [c.meshId],
        ),
      ),
    );
    var order = 3;
    final referenceIds = <String>[];
    for (final suggestion in c.references) {
      final id = 'stage:${suggestion.id}';
      stages.add(
        ReconstructionStage(
          id: id,
          type: ReconstructionStageType.reference,
          name: suggestion.recommendation,
          order: order++,
          priority: 90 - suggestion.order,
          dependencies: [
            referenceIds.isEmpty ? 'mesh:${c.meshId}' : referenceIds.last,
          ],
          sourceIds: suggestion.sourceIds,
          decision: decision(
            suggestion.confidence,
            suggestion.reason,
            suggestion.sourceIds,
          ),
        ),
      );
      referenceIds.add(id);
    }
    final sketchIds = <String>[];
    for (final suggestion in c.reconstruction.where(
      (s) => s.kind == SuggestionKind.sketch,
    )) {
      final id = 'stage:${suggestion.id}';
      stages.add(
        ReconstructionStage(
          id: id,
          type: ReconstructionStageType.sketch,
          name: suggestion.recommendation,
          order: order++,
          priority: 70,
          dependencies: referenceIds.isEmpty
              ? ['mesh:${c.meshId}']
              : [referenceIds.last],
          sourceIds: suggestion.sourceIds,
          decision: decision(
            suggestion.confidence,
            suggestion.reason,
            suggestion.sourceIds,
            risk: ReconstructionRisk.medium,
          ),
          parallelGroup: 'sketches',
        ),
      );
      sketchIds.add(id);
    }
    final surfaceIds = <String>[];
    for (final suggestion in c.surfaces) {
      final id = 'stage:${suggestion.id}';
      stages.add(
        ReconstructionStage(
          id: id,
          type: ReconstructionStageType.surface,
          name: suggestion.recommendation,
          order: order++,
          priority: 55,
          dependencies: sketchIds.isNotEmpty
              ? [...sketchIds]
              : referenceIds.isNotEmpty
              ? [referenceIds.last]
              : ['mesh:${c.meshId}'],
          sourceIds: suggestion.sourceIds,
          decision: decision(
            suggestion.confidence,
            suggestion.reason,
            suggestion.sourceIds,
            risk: suggestion.confidence < .6
                ? ReconstructionRisk.high
                : ReconstructionRisk.medium,
          ),
          parallelGroup: 'surfaces',
        ),
      );
      surfaceIds.add(id);
    }
    final featureIds = <String>[];
    for (final feature in c.features) {
      final id = 'stage:cad:${feature.id}', deps = <String>[];
      deps.addAll(surfaceIds.where((s) => feature.regionIds.any(s.contains)));
      if (deps.isEmpty) {
        deps.addAll(sketchIds.where((s) => feature.regionIds.any(s.contains)));
      }
      if (deps.isEmpty) {
        deps.add(referenceIds.isEmpty ? 'mesh:${c.meshId}' : referenceIds.last);
      }
      stages.add(
        ReconstructionStage(
          id: id,
          type: ReconstructionStageType.cadFeature,
          name: 'Plan ${feature.kind}',
          order: order++,
          priority: 40,
          dependencies: deps.toSet().toList(),
          sourceIds: [feature.id, ...feature.regionIds],
          decision: decision(
            feature.confidence,
            feature.explanation,
            [feature.id],
            risk: feature.confidence < .6
                ? ReconstructionRisk.high
                : ReconstructionRisk.medium,
          ),
          parallelGroup: 'features',
        ),
      );
      featureIds.add(id);
    }
    final solidId = 'stage:solid:${c.meshId}';
    stages.add(
      ReconstructionStage(
        id: solidId,
        type: ReconstructionStageType.solid,
        name: 'Solid completion placeholder',
        order: order++,
        priority: 20,
        dependencies: featureIds.isNotEmpty ? featureIds : surfaceIds,
        sourceIds: [c.meshId],
        decision: decision(
          .4,
          'Final solid creation is a future authorized CAD operation; this stage only records its dependencies.',
          [c.meshId],
          risk: ReconstructionRisk.high,
        ),
      ),
    );
    stages.add(
      ReconstructionStage(
        id: 'stage:validation:${c.meshId}',
        type: ReconstructionStageType.validation,
        name: 'Validate reconstruction against evidence',
        order: order,
        priority: 10,
        dependencies: [solidId],
        sourceIds: [c.meshId],
        decision: decision(
          .8,
          'Validate planned outcome against AREI evidence and Engineering DNA requirements.',
          [c.meshId],
        ),
      ),
    );
    final graph = ReconstructionDependencyGraph(stages),
        ordered = graph.topologicalOrder(),
        normalized = [
          for (var i = 0; i < ordered.length; i++)
            stages
                .firstWhere((s) => s.id == ordered[i])
                .copyWith(
                  order: i + 1,
                  status: i == 0
                      ? ReconstructionStageStatus.ready
                      : ReconstructionStageStatus.pending,
                ),
        ];
    final now = DateTime.now().toUtc();
    return ReconstructionWorkflow(
      id: input.previous?.id ?? 'workflow:${c.projectId}:${c.meshId}',
      projectId: c.projectId,
      meshId: c.meshId,
      revision: (input.previous?.revision ?? 0) + 1,
      stages: normalized,
      selectedStrategyId: strategy.id,
      createdAt: input.previous?.createdAt ?? now,
      updatedAt: now,
    );
  }
}
