import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/ai_engineering/ai_engineering.dart';
import 'package:flcad_mobile/core/engineering_feature_intelligence/engineering_feature_intelligence.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/interactive_engineering_assistant/interactive_engineering_assistant.dart';
import 'package:flcad_mobile/core/primitive_intelligence/primitive_intelligence.dart';
import 'package:flcad_mobile/core/reconstruction_strategy/reconstruction_strategy.dart';
import 'package:flcad_mobile/core/smart_reference/smart_reference.dart';
import 'package:flutter_test/flutter_test.dart';

(
  EngineeringFeatureSession,
  SmartReferenceSession,
  ReconstructionStrategySession,
)
sources(Directory project, String id, {bool reverse = false}) {
  final context = EngineeringContext(
    projectId: id,
    activePartId: 'part',
    patches: const ['patch'],
    boundaries: const ['boundary'],
    axes: const ['axis'],
    points: const ['point'],
    workflow: 'interactiveAssistant',
    activeModule: 'reconstructionStrategy',
    userContext: const {
      'objectives': ['accurate reconstruction', 'manufacturing readiness'],
    },
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
  final primitives = const PrimitiveIntelligenceFactory()
      .create(projectDirectory: project)
      .analyze(
        sessionId: '$id:primitives',
        context: context,
        primitives: reverse ? observations.reversed : observations,
      );
  final features = const EngineeringFeatureIntelligenceFactory()
      .create(projectDirectory: project)
      .analyze(sessionId: '$id:features', primitives: primitives);
  final references = const SmartReferenceFactory()
      .create(projectDirectory: project)
      .analyze(sessionId: '$id:references', features: features);
  final strategies = const ReconstructionStrategyFactory()
      .create(projectDirectory: project)
      .analyze(
        sessionId: '$id:strategies',
        features: features,
        references: references,
      );
  return (features, references, strategies);
}

void main() {
  late Directory project;
  setUp(
    () async =>
        project = await Directory.systemTemp.createTemp('flcad-assistant-'),
  );
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test(
    'consolidates only project context and emits evidence-based messages',
    () {
      final source = sources(project, 'project');
      final api = const InteractiveEngineeringAssistantFactory().create(
        projectDirectory: project,
      );
      final session = api.start(
        sessionId: 'assistant',
        features: source.$1,
        references: source.$2,
        strategies: source.$3,
      );
      expect(session.context.loadedPart, 'part');
      expect(session.context.primitiveCount, 2);
      expect(session.context.featureCount, greaterThan(0));
      expect(session.context.referenceCount, greaterThan(0));
      expect(session.context.projectObjectives, isNotEmpty);
      expect(session.context.toJson()['externalContextUsed'], isFalse);
      expect(session.messages.every((e) => e.evidence.isNotEmpty), isTrue);
      expect(
        session.suggestions.every(
          (e) => e.evidence.isNotEmpty && e.justification.isNotEmpty,
        ),
        isTrue,
      );
    },
  );

  test(
    'progress timeline and complete session snapshots support integral rollback',
    () {
      final source = sources(project, 'progress');
      final api = const InteractiveEngineeringAssistantFactory().create(
        projectDirectory: project,
      );
      var session = api.start(
        sessionId: 'progress',
        features: source.$1,
        references: source.$2,
        strategies: source.$3,
      );
      expect(session.progress.first.state, ProgressState.inProgress);
      expect(session.snapshots.single.playbook, isNotEmpty);
      expect(session.snapshots.single.references, isNotEmpty);
      expect(session.snapshots.single.strategies, isNotEmpty);
      expect(session.snapshots.single.history, isNotEmpty);
      expect(session.snapshots.single.analytics, isNotEmpty);
      session = api.completeStep(
        session.id,
        session.progress.first.stepId,
        'reviewed and completed',
      );
      expect(session.progress.first.state, ProgressState.completed);
      expect(session.timeline.last.event, contains('completed'));
      expect(session.snapshots, hasLength(2));
      session = api.rollback(session.id, 0);
      expect(session.progress.first.state, ProgressState.inProgress);
      expect(session.snapshots, hasLength(1));
    },
  );

  test('all engineering questions are answered from evidence', () {
    final source = sources(project, 'questions');
    final api = const InteractiveEngineeringAssistantFactory().create(
      projectDirectory: project,
    );
    final session = api.start(
      sessionId: 'questions',
      features: source.$1,
      references: source.$2,
      strategies: source.$3,
    );
    for (final question in EngineeringQuestion.values) {
      final answer = api.answer(session.id, question);
      expect(answer.answer, isNotEmpty);
      expect(answer.evidence, isNotEmpty);
      expect(answer.toJson()['externalContextUsed'], isFalse);
    }
  });

  test('strategy comparator alerts and suggestions are audit-ready', () {
    final source = sources(project, 'guidance');
    final api = const InteractiveEngineeringAssistantFactory().create(
      projectDirectory: project,
    );
    final session = api.start(
      sessionId: 'guidance',
      features: source.$1,
      references: source.$2,
      strategies: source.$3,
    );
    expect(session.comparisons.length, source.$3.strategies.length);
    expect(session.alerts, isNotEmpty);
    expect(session.suggestions, isNotEmpty);
    for (final comparison in session.comparisons) {
      expect(comparison.estimatedMinutes, greaterThan(0));
      expect(comparison.confidence, greaterThan(0));
    }
  });

  test(
    'suggestions require explicit acceptance or rejection and analytics are deterministic',
    () {
      final source = sources(project, 'decisions');
      final api = const InteractiveEngineeringAssistantFactory().create(
        projectDirectory: project,
      );
      var session = api.start(
        sessionId: 'decisions',
        features: source.$1,
        references: source.$2,
        strategies: source.$3,
      );
      final first = session.suggestions.first;
      expect(first.toJson()['requiresApproval'], isTrue);
      session = api.accept(session.id, first.id, 'engineer approved');
      session = api.reject(
        session.id,
        session.suggestions[1].id,
        'engineer rejected',
      );
      final analytics = api.analytics(session.id);
      expect(analytics.accepted, 1);
      expect(analytics.rejected, 1);
      expect(analytics.responseDuration, Duration.zero);
      expect(analytics.toJson()['internalTimers'], isFalse);
    },
  );

  test(
    'Project First persistence integration workspace and Property Inspector work',
    () async {
      final source = sources(project, 'integrated');
      final maps = List.generate(10, (_) => <String, dynamic>{});
      final integration = OfficialInteractiveAssistantIntegration(
        project: maps[0],
        aiFoundation: maps[1],
        primitiveIntelligence: maps[2],
        featureIntelligence: maps[3],
        smartReferences: maps[4],
        reconstructionStrategy: maps[5],
        workspace: maps[6],
        propertyInspector: maps[7],
        analytics: maps[8],
      );
      final api = const InteractiveEngineeringAssistantFactory().create(
        projectDirectory: project,
        integration: integration,
      );
      final session = api.start(
        sessionId: 'integrated',
        features: source.$1,
        references: source.$2,
        strategies: source.$3,
      );
      expect(await project.list().isEmpty, isTrue);
      final ui = InteractiveEngineeringWorkspace(
        session: session,
        analytics: api.analytics(session.id),
      );
      expect(integration.graph.isComplete, isTrue);
      expect(maps[1]['assistantContext'], isNotNull);
      expect(ui.propertyInspector['Panel'], 'Engineering Assistant');
      expect(ui.propertyInspector['Next Step'], isNotNull);
      expect(ui.propertyInspector['Recommendations'], isNotEmpty);
      await api.persist(session.id);
      for (final path in InteractiveAssistantRepository.paths) {
        expect(
          Directory(
            '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
    },
  );

  test('1,800 complete pipelines are reproducible', () {
    for (var index = 0; index < 1800; index++) {
      final firstSource = sources(project, 'project-$index');
      final secondSource = sources(project, 'project-$index', reverse: true);
      final first = const InteractiveEngineeringAssistantFactory().create(
        projectDirectory: project,
      );
      final second = const InteractiveEngineeringAssistantFactory().create(
        projectDirectory: project,
      );
      final a = first.start(
        sessionId: 'pipeline-$index',
        features: firstSource.$1,
        references: firstSource.$2,
        strategies: firstSource.$3,
      );
      final b = second.start(
        sessionId: 'pipeline-$index',
        features: secondSource.$1,
        references: secondSource.$2,
        strategies: secondSource.$3,
      );
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
      expect(
        jsonEncode(
          first.answer(a.id, EngineeringQuestion.whyStrategy).toJson(),
        ),
        jsonEncode(
          second.answer(b.id, EngineeringQuestion.whyStrategy).toJson(),
        ),
      );
    }
  });
}
