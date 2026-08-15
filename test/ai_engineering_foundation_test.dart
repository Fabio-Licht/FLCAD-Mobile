import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/ai_engineering/ai_engineering.dart';
import 'package:flutter_test/flutter_test.dart';

EngineeringContext context(String projectId) => EngineeringContext(
  projectId: projectId,
  activePartId: 'part-1',
  surfaces: const ['surface-1', 'surface-2'],
  patches: const ['patch-1', 'patch-2'],
  boundaries: const ['boundary-1'],
  planes: const ['xy'],
  operationHistory: const ['recognize', 'fit'],
  workflow: 'manufacturing',
  activeModule: 'manufacturing',
  manufacturingIntent: const {'process': 'milling'},
  userContext: const {'preferredIntent': 'manufacturing'},
  projectState: const {'saved': true},
  metrics: const {
    'cylinders': 2,
    'loops': 1,
    'continuity': .8,
    'curvature': .4,
    'area': 120,
    'availableVolume': 35,
    'symmetry': .9,
    'patterns': 1,
    'spatialDistribution': .7,
    'geometricScore': .8,
    'topologyScore': .7,
    'manufacturingScore': .9,
    'continuityScore': .8,
    'symmetryScore': .9,
    'historyScore': .6,
    'userPreferenceScore': 1,
  },
);

void main() {
  late Directory project;
  setUp(
    () async => project = await Directory.systemTemp.createTemp('flcad-ai-'),
  );
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test('bootstrap is passive, Project First, lazy and consultative', () async {
    final api = const AIEngineeringFactory().create(projectDirectory: project);
    expect(await project.list().isEmpty, isTrue);
    final session = api.start(
      sessionId: 'session-1',
      context: context('project-1'),
      requestedIntents: const [
        EngineeringIntentType.reconstruction,
        EngineeringIntentType.manufacturing,
      ],
    );
    expect(await project.list().isEmpty, isTrue);
    expect(session.intent.candidates, hasLength(2));
    expect(
      session.intent.candidates.every((e) => e.evidence.isNotEmpty),
      isTrue,
    );
    expect(
      session.intent.candidates.every(
        (e) => e.confidence.score.overallConfidence >= 0,
      ),
      isTrue,
    );
    final recommendations = api.recommendations(session.id);
    expect(recommendations, hasLength(2));
    expect(recommendations.first.toJson()['executesCommands'], isFalse);
    expect(recommendations.first.toJson()['geometryModified'], isFalse);
    await api.persist(session.id);
    expect(
      File(
        '${project.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}AIEngineering${Platform.pathSeparator}Sessions${Platform.pathSeparator}session-1.json',
      ).exists(),
      completion(isTrue),
    );
  });

  test('confidence is configurable, normalized and auditable', () {
    final weights = ConfidenceWeights({
      'geometric': 2,
      'topology': 1,
      'manufacturing': 1,
      'continuity': 1,
      'symmetry': 1,
      'history': 1,
      'userPreference': 1,
    });
    final result = ConfidenceEngine(weights).calculate(
      geometric: 1,
      topology: 0,
      manufacturing: 0,
      continuity: 0,
      symmetry: 0,
      history: 0,
      userPreference: 0,
    );
    expect(result.score.overallConfidence, .25);
    expect(result.toJson()['weights'], weights.values);
  });

  test(
    'decisions, history, analytics, rollback and persistence round-trip',
    () async {
      final api = const AIEngineeringFactory().create(
        projectDirectory: project,
      );
      var session = api.start(
        sessionId: 'audit-session',
        context: context('project-audit'),
        requestedIntents: const [EngineeringIntentType.manufacturing],
      );
      session = api.accept(
        session.id,
        session.intent.candidates.first.id,
        'verified',
      );
      expect(api.analytics(session.id).accepted, 1);
      session = api.rollback(session.id, 0);
      expect(session.history.decisions, isEmpty);
      session = api.reject(
        session.id,
        session.intent.candidates.first.id,
        'operator',
      );
      await api.persist(session.id);
      final loaded = await api.engine.repository.load(session.id);
      expect(jsonEncode(loaded.toJson()), jsonEncode(session.toJson()));
      expect(api.analytics(session.id).rejected, 1);
    },
  );

  test('official integration and AI Property Inspector are complete', () {
    final projectState = <String, dynamic>{};
    final workspaceState = <String, dynamic>{};
    final inspectorState = <String, dynamic>{};
    final analyticsState = <String, dynamic>{};
    final advisorState = <String, dynamic>{};
    final integration = OfficialAIEngineeringIntegration(
      project: projectState,
      workspace: workspaceState,
      propertyInspector: inspectorState,
      analytics: analyticsState,
      advisor: advisorState,
    );
    final api = const AIEngineeringFactory().create(
      projectDirectory: Directory.current.absolute,
      integration: integration,
    );
    final session = api.start(
      sessionId: 'integrated',
      context: context('project-integrated'),
      requestedIntents: const [EngineeringIntentType.inspection],
    );
    final ui = AIEngineeringWorkspace(
      session: session,
      recommendations: api.recommendations(session.id),
      analytics: api.analytics(session.id),
    );
    expect(integration.graph.isComplete, isTrue);
    expect(integration.graph.workflow.last, 'Live Reconstruction');
    expect(ui.panels, containsAll(['Timeline', 'Property Inspector']));
    expect(ui.propertyInspector['Evidence'], isNotEmpty);
    expect(ui.propertyInspector['Technical Justification'], isNotNull);
    expect(ui.propertyInspector['Geometry Modified'], isFalse);
    expect(advisorState['automaticActions'], isFalse);
  });

  test('500 complete pipelines are reproducible', () {
    for (var index = 0; index < 500; index++) {
      final first = const AIEngineeringFactory().create(
        projectDirectory: project,
      );
      final second = const AIEngineeringFactory().create(
        projectDirectory: project,
      );
      final id = 'pipeline-$index';
      final a = first.start(
        sessionId: id,
        context: context('project-$index'),
        requestedIntents: EngineeringIntentType.values,
      );
      final b = second.start(
        sessionId: id,
        context: context('project-$index'),
        requestedIntents: EngineeringIntentType.values.reversed,
      );
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
      expect(
        jsonEncode(first.recommendations(id).map((e) => e.toJson()).toList()),
        jsonEncode(second.recommendations(id).map((e) => e.toJson()).toList()),
      );
    }
  });
}
