import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/ai_engineering/ai_engineering.dart';
import 'package:flcad_mobile/core/engineering_feature_intelligence/engineering_feature_intelligence.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/primitive_intelligence/primitive_intelligence.dart';
import 'package:flcad_mobile/core/smart_reference/smart_reference.dart';
import 'package:flutter_test/flutter_test.dart';

EngineeringFeatureSession features(
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
    workflow: 'smartReferences',
    activeModule: 'featureIntelligence',
  ).snapshot();
  final values = [
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
        sessionId: '$id:primitive',
        context: context,
        primitives: reverse ? values.reversed : values,
      );
  return const EngineeringFeatureIntelligenceFactory()
      .create(projectDirectory: project)
      .analyze(sessionId: '$id:features', primitives: primitiveSession);
}

void main() {
  late Directory project;
  setUp(
    () async =>
        project = await Directory.systemTemp.createTemp('flcad-reference-'),
  );
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test('builds ranked explainable candidates with canonical references', () {
    final api = const SmartReferenceFactory().create(projectDirectory: project);
    final session = api.analyze(
      sessionId: 'references',
      features: features(project, 'project'),
    );
    expect(session.candidates, isNotEmpty);
    expect(session.candidates.every((e) => e.evidence.isNotEmpty), isTrue);
    expect(
      session.candidates.first.scores.toJson().keys,
      containsAll([
        'geometricScore',
        'topologyScore',
        'manufacturingScore',
        'functionalScore',
        'symmetryScore',
        'featureScore',
        'contextScore',
        'historyScore',
        'overallConfidence',
      ]),
    );
    expect(session.candidates.first.canonical.angularErrorDegrees, .18);
    expect(session.candidates.first.canonical.toJson()['applied'], isFalse);
    expect(
      api.recommendations(session.id).first.toJson()['entitiesCreated'],
      isFalse,
    );
  });

  test('candidate builder exposes every requested reference type', () {
    final builder = ReferenceCandidateBuilder(
      ranking: ReferenceRankingEngine(ReferenceRankingWeights.equal),
    );
    expect(builder.supportedTypes, ReferenceCandidateType.values);
  });

  test('dependency graph is acyclic and rejects cycles', () {
    final session = const SmartReferenceFactory()
        .create(projectDirectory: project)
        .analyze(sessionId: 'graph', features: features(project, 'graph'));
    expect(session.graph.toJson()['acyclic'], isTrue);
    expect(
      () => ReferenceDependencyGraph(
        nodes: const ['a', 'b'],
        dependencies: const [
          ReferenceDependency(from: 'a', to: 'b', reason: 'one'),
          ReferenceDependency(from: 'b', to: 'a', reason: 'two'),
        ],
      ),
      throwsArgumentError,
    );
  });

  test(
    'Datum A B C coordinate systems and three alignment strategies are consultative',
    () {
      final session = const SmartReferenceFactory()
          .create(projectDirectory: project)
          .analyze(
            sessionId: 'strategies',
            features: features(project, 'strategies'),
          );
      expect(session.datums.map((e) => e.label), [
        DatumLabel.a,
        DatumLabel.b,
        DatumLabel.c,
      ]);
      expect(session.strategies, hasLength(3));
      expect(session.strategies.every((e) => e.evidenceIds.isNotEmpty), isTrue);
      expect(
        session.strategies.every((e) => e.toJson()['applied'] == false),
        isTrue,
      );
      expect(session.coordinateSystems, isNotEmpty);
    },
  );

  test(
    'accept reject rollback analytics and Project First persistence work',
    () async {
      final api = const SmartReferenceFactory().create(
        projectDirectory: project,
      );
      var session = api.analyze(
        sessionId: 'audit',
        features: features(project, 'audit'),
      );
      expect(await project.list().isEmpty, isTrue);
      session = api.accept(
        session.id,
        session.candidates.first.id,
        'engineer approved',
      );
      expect(api.analytics(session.id).accepted, 1);
      session = api.rollback(session.id, 0);
      session = api.reject(
        session.id,
        session.candidates.first.id,
        'engineer rejected',
      );
      expect(api.analytics(session.id).rejected, 1);
      await api.persist(session.id);
      for (final path in SmartReferenceRepository.paths) {
        expect(
          Directory(
            '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
    },
  );

  test(
    'official integration workspace and Property Inspector are complete',
    () {
      final projectMap = <String, dynamic>{},
          ai = <String, dynamic>{},
          primitive = <String, dynamic>{},
          feature = <String, dynamic>{},
          workspace = <String, dynamic>{},
          inspector = <String, dynamic>{},
          analytics = <String, dynamic>{};
      final integration = OfficialSmartReferenceIntegration(
        project: projectMap,
        aiFoundation: ai,
        primitiveIntelligence: primitive,
        featureIntelligence: feature,
        workspace: workspace,
        propertyInspector: inspector,
        analytics: analytics,
      );
      final api = const SmartReferenceFactory().create(
        projectDirectory: project,
        integration: integration,
      );
      final session = api.analyze(
        sessionId: 'integrated',
        features: features(project, 'integrated'),
      );
      final ui = SmartReferenceWorkspace(
        session: session,
        recommendations: api.recommendations(session.id),
        analytics: api.analytics(session.id),
      );
      expect(integration.graph.isComplete, isTrue);
      expect(ai['referenceCandidates'], isNotEmpty);
      expect(ui.propertyInspector['Panel'], 'Smart References');
      expect(ui.propertyInspector['Feature Graph Related'], isNotEmpty);
      expect(ui.propertyInspector['Primitive Graph Related'], isNotEmpty);
      expect(ui.propertyInspector['Alignment Strategy'], isNotEmpty);
      expect(ui.propertyInspector['Geometry Modified'], isFalse);
    },
  );

  test('1,200 complete pipelines are reproducible', () {
    for (var index = 0; index < 1200; index++) {
      final first = const SmartReferenceFactory().create(
        projectDirectory: project,
      );
      final second = const SmartReferenceFactory().create(
        projectDirectory: project,
      );
      final a = first.analyze(
        sessionId: 'pipeline-$index',
        features: features(project, 'project-$index'),
      );
      final b = second.analyze(
        sessionId: 'pipeline-$index',
        features: features(project, 'project-$index', reverse: true),
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
