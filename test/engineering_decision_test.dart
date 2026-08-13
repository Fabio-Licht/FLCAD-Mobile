import 'dart:io';

import 'package:flcad_mobile/core/engineering_decision/api/decision_api.dart';
import 'package:flcad_mobile/core/engineering_decision/commands/fel_decision_commands.dart';
import 'package:flcad_mobile/core/engineering_decision/engine/engineering_decision_engine.dart';
import 'package:flcad_mobile/core/engineering_decision/goals/goal_engine.dart';
import 'package:flcad_mobile/core/engineering_decision/integration/professional_workflow_decision_adapter.dart';
import 'package:flcad_mobile/core/engineering_decision/models/decision_models.dart';
import 'package:flcad_mobile/core/engineering_decision/memory/decision_memory.dart';
import 'package:flcad_mobile/core/engineering_decision/plugins/decision_plugin.dart';
import 'package:flcad_mobile/core/engineering_decision/policies/decision_policy.dart';
import 'package:flcad_mobile/core/engineering_decision/scoring/multi_criteria_decision.dart';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/professional_workflow/models/workflow_models.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _criteria = DecisionCriteria(
  recognitionConfidence: .9,
  meshQuality: .8,
  captureCompleteness: .75,
  computationalCost: .3,
  reconstructionImpact: .95,
  referenceReuse: .7,
  partComplexity: .4,
  engineeringIntent: .85,
  successHistory: .8,
);

DecisionRequest request({
  String project = 'p',
  List<String> dependencies = const [],
  String? region,
}) => DecisionRequest(
  projectId: project,
  type: EngineeringDecisionType.reference,
  origin: DecisionOrigin.cognition,
  title: 'Criar plano base',
  criteria: _criteria,
  evidence: const [
    DecisionEvidence(
      id: 'plane',
      description: 'Base plana detectada',
      source: 'Engineering Cognition',
      value: .94,
      ruleIds: ['flat-base'],
    ),
  ],
  impact: 'Estabelece referência primária.',
  dependencies: dependencies,
  regionId: region,
);

void main() {
  test('multi-criteria score is reproducible and policy-sensitive', () {
    const system = MultiCriteriaDecisionSystem();
    final precision = system.score(
      _criteria,
      DecisionPolicyProfile.forPolicy(DecisionPolicy.precision),
    );
    final speed = system.score(
      _criteria,
      DecisionPolicyProfile.forPolicy(DecisionPolicy.speed),
    );
    expect(precision.value, inInclusiveRange(0, 1));
    expect(precision.value, isNot(speed.value));
    expect(
      system
          .score(
            _criteria,
            DecisionPolicyProfile.forPolicy(DecisionPolicy.precision),
          )
          .value,
      precision.value,
    );
  });

  test(
    'engine creates explainable decision, alternatives and graph integration',
    () async {
      final engine = EngineeringDecisionEngine();
      final decision = await engine.decide(request(region: 'region-a'));
      expect(decision.evidence.single.ruleIds, contains('flat-base'));
      expect(decision.justification, contains('precision'));
      expect(decision.alternatives.map((a) => a.kind), [
        'primary',
        'alternative',
        'conservative',
      ]);
      expect(decision.regionId, 'region-a');
      expect(engine.graph.engineeringGraph.nodes, contains(decision.id));
      expect((await engine.repository.findAll('p')).single.id, decision.id);
    },
  );

  test(
    'decision graph enforces dependencies and reports downstream impact',
    () async {
      final engine = EngineeringDecisionEngine();
      final first = await engine.decide(request());
      final second = await engine.decide(request(dependencies: [first.id]));
      expect(engine.graph.impact(first.id), contains(second.id));
      expect(
        () => engine.decide(request(dependencies: ['missing'])),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('human override feeds memory, timeline and analytics', () async {
    final engine = EngineeringDecisionEngine();
    final decision = await engine.decide(request());
    final accepted = await engine.override(
      decision.id,
      'p',
      DecisionStatus.accepted,
      actor: 'engineer',
      reason: 'Evidence reviewed',
    );
    expect(accepted.revision, 2);
    expect(
      (await engine.memory.store.load('p')).single.reason,
      'Evidence reviewed',
    );
    expect(engine.timeline.last.action, 'accepted');
    expect(engine.analytics().acceptanceRate, 1);
  });

  test('project decision memory survives a new store instance', () async {
    final root = await Directory.systemTemp.createTemp('ede_memory_');
    addTearDown(() => root.delete(recursive: true));
    final storage = LocalStorageService(rootDirectory: root);
    final first = ProjectDecisionMemoryStore(storage: storage);
    await first.save(
      'p',
      DecisionMemoryRecord(
        'd',
        DecisionStatus.accepted,
        'reviewed',
        'valid',
        DateTime.utc(2026),
        'engineer',
      ),
    );
    final records = await ProjectDecisionMemoryStore(
      storage: storage,
    ).load('p');
    expect(records.single.decisionId, 'd');
    expect(records.single.status, DecisionStatus.accepted);
  });

  test('simulation compares alternatives without changing decision', () async {
    final engine = EngineeringDecisionEngine();
    final decision = await engine.decide(request());
    final simulation = engine.simulate(decision.id, 'conservative');
    expect(simulation.impact, contains('nenhuma alteração foi executada'));
    expect(engine.graph.find(decision.id)?.status, DecisionStatus.proposed);
  });

  test('goal engine enforces prerequisites and completion criteria', () {
    final goals = GoalEngine()
      ..add(
        const EngineeringGoal(
          id: 'base',
          projectId: 'p',
          title: 'Base',
          completionCriteria: ['validated'],
        ),
      )
      ..add(
        const EngineeringGoal(
          id: 'part',
          projectId: 'p',
          title: 'Peça',
          prerequisiteIds: ['base'],
          completionCriteria: ['reviewed'],
        ),
      );
    expect(() => goals.complete('part', ['reviewed']), throwsStateError);
    goals.complete('base', ['validated']);
    goals.complete('part', ['reviewed']);
    expect(goals.find('part')?.completed, isTrue);
  });

  test(
    'plugins add evidence and evaluators through a stable contract',
    () async {
      final plugins = DecisionPluginRegistry()..register(_Plugin());
      final engine = EngineeringDecisionEngine(plugins: plugins);
      final decision = await engine.decide(request());
      expect(decision.evidence.map((e) => e.id), contains('plugin-evidence'));
      expect(() => plugins.register(_Plugin()), throwsStateError);
    },
  );

  test('workflow adapter preserves explanation and regional target', () async {
    final decision = await EngineeringDecisionEngine().decide(
      request(region: 'r'),
    );
    final recommendation = const ProfessionalWorkflowDecisionAdapter()
        .toRecommendation(decision, ProfessionalWorkflowStage.createReferences);
    expect(recommendation.targetArtifactId, 'r');
    expect(
      recommendation.decision.evidence.single.source,
      'Engineering Cognition',
    );
    expect(recommendation.decision.alternatives, hasLength(3));
  });

  test('FEL registers the complete decision vocabulary', () {
    final names = createNativeCommandRegistry().names;
    for (final command in createDecisionFELCommands(api: DecisionApi())) {
      expect(names, contains(command.name));
    }
  });
}

class _Plugin implements DecisionPlugin {
  @override
  String get id => 'test';
  @override
  String get version => '1.0.0';
  @override
  bool get compatible => true;
  @override
  Iterable<DecisionEvidence> evidence(DecisionRequest request) => const [
    DecisionEvidence(
      id: 'plugin-evidence',
      description: 'Plugin observation',
      source: 'test-plugin',
      value: .8,
    ),
  ];
  @override
  DecisionCriteria evaluate(DecisionRequest request) => request.criteria;
}
