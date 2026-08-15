import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/ai_engineering/ai_engineering.dart';
import 'package:flcad_mobile/core/engineering_feature_intelligence/engineering_feature_intelligence.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/primitive_intelligence/primitive_intelligence.dart';
import 'package:flcad_mobile/core/reconstruction_strategy/reconstruction_strategy.dart';
import 'package:flcad_mobile/core/smart_reference/smart_reference.dart';
import 'package:flutter_test/flutter_test.dart';

(EngineeringFeatureSession, SmartReferenceSession) sources(
  Directory project,
  String id, {
  bool reverse = false,
}) {
  final context = EngineeringContext(
    projectId: id,
    activePartId: 'part',
    patches: const ['patch'],
    boundaries: const ['boundary'],
    axes: const ['axis'],
    points: const ['point'],
    workflow: 'reconstructionStrategy',
    activeModule: 'smartReferences',
  ).snapshot();
  final observations = [
    for (final primitiveId in const ['c1', 'c2'])
      PrimitiveObservation(
        id: primitiveId,
        type: PrimitiveType.cylinder,
        measures: const {
          'radius': 5,
          'length': 20,
          'coaxiality': .98,
          'patternGroup': 1,
          'patternKind': 1,
          'patternScore': .97,
          'importance': .9,
          'manufacturingRelevance': .95,
          'alignmentRelevance': .92,
          'reconstructionRelevance': .96,
          'featureTopologyScore': .94,
          'featureFunctionalScore': .93,
          'featureContextScore': .91,
          'featureHistoryScore': .9,
          'canonicalDeviation': .18,
        },
        vectors: const {
          'axis': [0, 0, 1],
        },
        adjacentIds: const ['shoulder'],
        recognitionConfidence: .98,
      ),
  ];
  final primitiveSession = const PrimitiveIntelligenceFactory()
      .create(projectDirectory: project)
      .analyze(
        sessionId: '$id:primitives',
        context: context,
        primitives: reverse ? observations.reversed : observations,
      );
  final features = const EngineeringFeatureIntelligenceFactory()
      .create(projectDirectory: project)
      .analyze(sessionId: '$id:features', primitives: primitiveSession);
  final references = const SmartReferenceFactory()
      .create(projectDirectory: project)
      .analyze(sessionId: '$id:references', features: features);
  return (features, references);
}

void main() {
  late Directory project;
  setUp(
    () async =>
        project = await Directory.systemTemp.createTemp('flcad-strategy-'),
  );
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test('creates complete auditable Playbook and at least three strategies', () {
    final source = sources(project, 'project');
    final api = const ReconstructionStrategyFactory().create(
      projectDirectory: project,
    );
    final session = api.analyze(
      sessionId: 'planning',
      features: source.$1,
      references: source.$2,
    );
    expect(session.strategies.length, greaterThanOrEqualTo(3));
    expect(
      session.strategies.map((e) => e.manufacturingVariant).toSet(),
      ManufacturingVariant.values.toSet(),
    );
    expect(session.playbook.steps, isNotEmpty);
    expect(session.playbook.toJson()['executed'], isFalse);
    for (final strategy in session.strategies) {
      expect(strategy.estimatedDuration, isNot(Duration.zero));
      expect(strategy.justification, isNotEmpty);
      expect(strategy.steps.every((e) => e.justification.isNotEmpty), isTrue);
      expect(strategy.graph.toJson()['acyclic'], isTrue);
    }
  });

  test('dependency scheduler rejects cycles', () {
    expect(
      () => StrategyDependencyGraph(
        nodes: const ['a', 'b'],
        dependencies: const [
          StrategyDependency(from: 'a', to: 'b', reason: 'one'),
          StrategyDependency(from: 'b', to: 'a', reason: 'two'),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('reasoning and advisor expose complete explainability', () {
    final source = sources(project, 'explain');
    final api = const ReconstructionStrategyFactory().create(
      projectDirectory: project,
    );
    final session = api.analyze(
      sessionId: 'explain',
      features: source.$1,
      references: source.$2,
    );
    final recommendation = api.recommendations(session.id).first.toJson();
    expect(recommendation['justification'], isNotEmpty);
    expect(recommendation['evidence'], isNotEmpty);
    expect(recommendation['referencesUsed'], isNotEmpty);
    expect(recommendation['features'], isNotEmpty);
    expect(recommendation['primitiveGraph'], isNotEmpty);
    expect(recommendation['featureGraph'], isNotEmpty);
    expect(recommendation['smartReferences'], isNotEmpty);
    expect(recommendation['discardedHypotheses'], isA<List<dynamic>>());
    expect(recommendation['commandsExecuted'], isFalse);
  });

  test('steps can be accepted edited rejected and rolled back', () {
    final source = sources(project, 'decisions');
    final api = const ReconstructionStrategyFactory().create(
      projectDirectory: project,
    );
    var session = api.analyze(
      sessionId: 'decisions',
      features: source.$1,
      references: source.$2,
    );
    final strategy = session.strategies.first;
    final step = strategy.steps.first;
    session = api.accept(
      session.id,
      strategy.id,
      'approved step',
      stepId: step.id,
    );
    session = api.editStep(
      sessionId: session.id,
      strategyId: strategy.id,
      stepId: step.id,
      objective: 'Engineer-adjusted objective',
      justification: 'Engineer supplied technical adjustment.',
      reason: 'manual review',
    );
    expect(session.strategies.first.steps.first.revision, 1);
    expect(
      session.playbook.auditVersion,
      strategy.id == session.playbook.recommendedStrategyId ? 1 : 0,
    );
    session = api.reject(session.id, strategy.id, 'alternative rejected');
    expect(api.analytics(session.id).accepted, 1);
    expect(api.analytics(session.id).edited, 1);
    expect(api.analytics(session.id).rejected, 1);
    session = api.rollback(session.id, 0);
    expect(session.decisions, isEmpty);
    expect(session.strategies.first.steps.first.revision, 0);
  });

  test('difficulty analytics and Project First persistence work', () async {
    final source = sources(project, 'persist');
    final api = const ReconstructionStrategyFactory().create(
      projectDirectory: project,
    );
    final session = api.analyze(
      sessionId: 'persist',
      features: source.$1,
      references: source.$2,
    );
    expect(await project.list().isEmpty, isTrue);
    expect(session.difficulty.featureCount, source.$1.hypotheses.length);
    expect(api.analytics(session.id).strategiesGenerated, 5);
    await api.persist(session.id);
    for (final path in ReconstructionStrategyRepository.paths) {
      expect(
        Directory(
          '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
        ).existsSync(),
        isTrue,
      );
    }
  });

  test(
    'official integration workspace and Property Inspector are complete',
    () {
      final source = sources(project, 'integrated');
      final projectMap = <String, dynamic>{},
          ai = <String, dynamic>{},
          primitive = <String, dynamic>{},
          feature = <String, dynamic>{},
          references = <String, dynamic>{},
          workspace = <String, dynamic>{},
          inspector = <String, dynamic>{},
          analytics = <String, dynamic>{};
      final integration = OfficialReconstructionStrategyIntegration(
        project: projectMap,
        aiFoundation: ai,
        primitiveIntelligence: primitive,
        featureIntelligence: feature,
        smartReferences: references,
        workspace: workspace,
        propertyInspector: inspector,
        analytics: analytics,
      );
      final api = const ReconstructionStrategyFactory().create(
        projectDirectory: project,
        integration: integration,
      );
      final session = api.analyze(
        sessionId: 'integrated',
        features: source.$1,
        references: source.$2,
      );
      final ui = ReconstructionStrategyWorkspace(
        session: session,
        recommendations: api.recommendations(session.id),
        analytics: api.analytics(session.id),
      );
      expect(integration.graph.isComplete, isTrue);
      expect(ai['engineeringPlaybook'], isNotNull);
      expect(ui.propertyInspector['Panel'], 'Reconstruction Strategy');
      expect(ui.propertyInspector['Steps'], isNotEmpty);
      expect(ui.propertyInspector['Dependencies'], isNotNull);
      expect(ui.propertyInspector['Geometry Modified'], isFalse);
    },
  );

  test('1,500 complete pipelines are reproducible', () {
    for (var index = 0; index < 1500; index++) {
      final firstSource = sources(project, 'project-$index');
      final secondSource = sources(project, 'project-$index', reverse: true);
      final first = const ReconstructionStrategyFactory().create(
        projectDirectory: project,
      );
      final second = const ReconstructionStrategyFactory().create(
        projectDirectory: project,
      );
      final a = first.analyze(
        sessionId: 'pipeline-$index',
        features: firstSource.$1,
        references: firstSource.$2,
      );
      final b = second.analyze(
        sessionId: 'pipeline-$index',
        features: secondSource.$1,
        references: secondSource.$2,
      );
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
      expect(
        jsonEncode(first.recommendations(a.id).map((e) => e.toJson()).toList()),
        jsonEncode(
          second.recommendations(b.id).map((e) => e.toJson()).toList(),
        ),
      );
    }
  });
}
