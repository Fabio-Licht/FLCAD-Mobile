import 'dart:io';

import 'dart:math' as math;
import 'package:flcad_mobile/core/engineering_reconstruction/advisor/reconstruction_intelligence_advisor.dart';
import 'package:flcad_mobile/core/engineering_reconstruction/api/engineering_reconstruction_api.dart';
import 'package:flcad_mobile/core/engineering_reconstruction/graph/reconstruction_graph.dart';
import 'package:flcad_mobile/core/engineering_reconstruction/memory/reconstruction_memory.dart';
import 'package:flcad_mobile/core/engineering_reconstruction/models/reconstruction_intelligence_models.dart';
import 'package:flcad_mobile/core/engineering_reconstruction/planner/engineering_reconstruction_planner.dart';
import 'package:flcad_mobile/core/engineering_reconstruction/templates/reconstruction_templates.dart';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/professional_recognition/engine/professional_recognition_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Future<dynamic> report() => ProfessionalRecognitionEngine().recognize([
  RecognitionContext(
    observation: RecognitionObservation(
      projectId: 'p',
      meshId: 'm',
      regionId: 'c',
      points: [
        for (final z in [-2.0, -1.0, 0.0, 1.0, 2.0])
          for (var i = 0; i < 12; i++)
            Vector3(math.cos(i * math.pi / 6), math.sin(i * math.pi / 6), z),
      ],
      meshFingerprint: 'm',
      regionFingerprint: 'c',
    ),
    areiConfidence: .8,
    cognitionConfidence: .8,
  ),
]);

void main() {
  test(
    'planner creates progressive DAG, strategies, scores and explainable next step',
    () async {
      final plan = await EngineeringReconstructionPlanner().plan(
        ERIPlanningInput(await report()),
      );
      expect(plan.strategies, hasLength(3));
      expect(
        plan.nodes.map((e) => e.level),
        containsAll([
          ReconstructionLevel.references,
          ReconstructionLevel.sketches,
          ReconstructionLevel.features,
          ReconstructionLevel.solidPlan,
        ]),
      );
      expect(plan.nodes.first.status, ERINodeStatus.ready);
      expect(plan.nodes.first.priority, greaterThan(plan.nodes.last.priority));
      expect(plan.score.total, inInclusiveRange(0, 1));
      expect(plan.analytics.steps, plan.nodes.length);
      final advice = const ReconstructionIntelligenceAdvisor().next(plan)!;
      expect(advice.why, isNotEmpty);
      expect(advice.alternatives, isNotEmpty);
    },
  );

  test('dependency solver rejects missing dependencies and cycles', () {
    ERIPlanNode node(String id, List<String> deps) => ERIPlanNode(
      id: id,
      type: ERINodeType.reference,
      level: ReconstructionLevel.references,
      title: id,
      dependencies: deps,
      alternatives: const [],
      cost: 0,
      risk: ERIRisk.low,
      confidence: 1,
      impact: 'i',
      priority: 1,
      explanation: 'e',
      sourceIds: const [],
    );
    expect(
      () => ERIReconstructionGraph([
        node('a', ['missing']),
      ]),
      throwsStateError,
    );
    expect(
      () => ERIReconstructionGraph([
        node('a', ['b']),
        node('b', ['a']),
      ]),
      throwsStateError,
    );
  });

  test(
    'human collaboration records revision and intervention without geometry',
    () async {
      final api = EngineeringReconstructionApi(),
          plan = await api.plan(await report());
      final updated = await api.override(
        plan.nodes.first.id,
        ERINodeStatus.accepted,
        actor: 'engineer',
        reason: 'Datum reviewed',
      );
      expect(updated.revision, plan.revision + 1);
      expect(updated.timeline.last.actor, 'engineer');
      expect(updated.nodes.first.status, ERINodeStatus.accepted);
      expect(api.exportPlan(), contains('flcad.eri-plan'));
    },
  );

  test('incremental replan preserves unaffected human state', () async {
    final api = EngineeringReconstructionApi(),
        first = await api.plan(await report());
    await api.override(
      first.nodes.first.id,
      ERINodeStatus.accepted,
      actor: 'e',
      reason: 'ok',
    );
    final changed = api.current.nodes
        .where((n) => n.type == ERINodeType.feature)
        .first
        .sourceIds
        .first;
    final replanned = await api.replan(await report(), [changed]);
    expect(replanned.revision, api.current.revision);
    expect(
      replanned.nodes.firstWhere((n) => n.id == 'reference:base').status,
      ERINodeStatus.accepted,
    );
    expect(replanned.timeline.last.action, 'replanned');
  });

  test('template library covers requested professional part families', () {
    expect(ReconstructionTemplateLibrary.values, hasLength(10));
    expect(
      const ReconstructionTemplateLibrary().select(['fundido'])?.id,
      'casting',
    );
    expect(const ReconstructionTemplateLibrary().select(['unknown']), isNull);
  });

  test('memory tracks winning and discarded strategy outcomes', () {
    final memory = ReconstructionMemory()
      ..save(
        ReconstructionMemoryRecord(
          'p',
          'a',
          'accepted',
          const Duration(minutes: 2),
          1,
          DateTime.now(),
        ),
      )
      ..save(
        ReconstructionMemoryRecord(
          'p',
          'a',
          'rejected',
          const Duration(minutes: 3),
          2,
          DateTime.now(),
        ),
      );
    expect(memory.strategySuccess()['a'], .5);
    expect(memory.forProject('p'), hasLength(2));
  });

  test('FEL exposes complete ERI planning vocabulary', () {
    final names = createNativeCommandRegistry(Directory.systemTemp).names;
    for (final name in [
      'PLAN RECONSTRUCTION',
      'SHOW PLAN',
      'SHOW STRATEGIES',
      'SHOW DEPENDENCIES',
      'SHOW NEXT STEP',
      'SHOW TIMELINE',
      'SHOW RISK',
      'REPLAN',
      'EXPORT PLAN',
      'COMPARE STRATEGIES',
    ]) {
      expect(names, contains(name));
    }
  });
}
