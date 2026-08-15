import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/ai_engineering/ai_engineering.dart';
import 'package:flcad_mobile/core/engineering_feature_intelligence/engineering_feature_intelligence.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/primitive_intelligence/primitive_intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

EngineeringContext context(String id) => EngineeringContext(
  projectId: id,
  activePartId: 'part',
  patches: const ['patch-1'],
  boundaries: const ['boundary-1'],
  axes: const ['axis-1'],
  points: const ['point-1'],
  workflow: 'engineeringFeatureIntelligence',
  activeModule: 'primitiveIntelligence',
);

PrimitiveObservation observation(
  String id, {
  int? featureCode,
  double group = 1,
  PatternKind pattern = PatternKind.circular,
}) => PrimitiveObservation(
  id: id,
  type: PrimitiveType.cylinder,
  measures: {
    'radius': 5,
    'length': 20,
    'coaxiality': .95,
    'patternGroup': group,
    'patternKind': pattern.index.toDouble(),
    'patternScore': .96,
    'importance': .9,
    'manufacturingRelevance': .95,
    'alignmentRelevance': .9,
    'reconstructionRelevance': 1,
    'featureTopologyScore': .98,
    'featureFunctionalScore': .97,
    'featureContextScore': .9,
    'featureHistoryScore': .8,
    'canonicalDeviation': .02,
    if (featureCode != null) 'featureCode': featureCode.toDouble(),
  },
  vectors: const {
    'axis': [0, 0, 1],
  },
  adjacentIds: const ['shoulder'],
  recognitionConfidence: .99,
);

PrimitiveIntelligenceSession primitives(
  Directory project,
  String id,
  List<PrimitiveObservation> values,
) => const PrimitiveIntelligenceFactory()
    .create(projectDirectory: project)
    .analyze(
      sessionId: '$id:primitives',
      context: context(id).snapshot(),
      primitives: values,
    );

void main() {
  late Directory project;
  setUp(
    () async =>
        project = await Directory.systemTemp.createTemp('flcad-features-'),
  );
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test(
    'recognizes composite features with graph, tree, evidence and strategy',
    () {
      final source = primitives(project, 'project', [
        observation('c1'),
        observation('c2'),
      ]);
      final api = const EngineeringFeatureIntelligenceFactory().create(
        projectDirectory: project,
      );
      final session = api.analyze(sessionId: 'features', primitives: source);
      expect(
        session.hypotheses.any((e) => e.type == EngineeringFeatureType.flange),
        isTrue,
      );
      for (final feature in session.hypotheses) {
        expect(feature.graph.toJson()['acyclic'], isTrue);
        expect(feature.confidenceTree.children, hasLength(7));
        expect(feature.evidence, isNotEmpty);
        expect(feature.justification, contains('graph relationships'));
        expect(feature.strategy.toJson()['executed'], isFalse);
        expect(feature.canonicalSuggestion.toJson()['applied'], isFalse);
      }
    },
  );

  test('feature library supports every requested canonical feature', () {
    final values = [
      for (final type in EngineeringFeatureType.values)
        observation(
          'p-${type.index}',
          featureCode: type.index,
          group: 100 + type.index.toDouble(),
          pattern: PatternKind.linear,
        ),
    ];
    final api = const EngineeringFeatureIntelligenceFactory().create(
      projectDirectory: project,
    );
    final session = api.analyze(
      sessionId: 'library',
      primitives: primitives(project, 'library', values),
    );
    expect(
      session.hypotheses.map((e) => e.type).toSet(),
      containsAll(EngineeringFeatureType.values),
    );
  });

  test('feature graph rejects cycles', () {
    expect(
      () => FeatureGraph(
        id: 'cycle',
        nodes: const [
          FeatureGraphNode(id: 'a', kind: 'plane', referenceId: 'a'),
          FeatureGraphNode(id: 'b', kind: 'axis', referenceId: 'b'),
        ],
        edges: const [
          FeatureGraphEdge(
            from: 'a',
            to: 'b',
            relationship: FeatureRelationshipType.dependency,
            score: 1,
          ),
          FeatureGraphEdge(
            from: 'b',
            to: 'a',
            relationship: FeatureRelationshipType.dependency,
            score: 1,
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test(
    'explainability answers why, evidence, primitives, relations, scores and discarded hypotheses',
    () {
      final api = const EngineeringFeatureIntelligenceFactory().create(
        projectDirectory: project,
      );
      final session = api.analyze(
        sessionId: 'explain',
        primitives: primitives(project, 'explain', [
          observation(
            'bearing',
            featureCode: EngineeringFeatureType.bearingSeat.index,
          ),
        ]),
      );
      final recommendation = api.recommendations(session.id).single.toJson();
      expect(recommendation['why'], isNotEmpty);
      expect(recommendation['evidence'], isNotEmpty);
      expect(recommendation['primitives'], isNotEmpty);
      expect(recommendation['relationships'], isNotEmpty);
      expect(recommendation['scores'], isNotEmpty);
      expect(recommendation['discardedHypotheses'], isA<List<dynamic>>());
      expect(recommendation['commandsExecuted'], isFalse);
    },
  );

  test(
    'decisions rollback analytics persistence and Engineering DNA work',
    () async {
      final api = const EngineeringFeatureIntelligenceFactory().create(
        projectDirectory: project,
      );
      var session = api.analyze(
        sessionId: 'audit',
        primitives: primitives(project, 'audit', [
          observation(
            'bearing',
            featureCode: EngineeringFeatureType.bearingSeat.index,
          ),
        ]),
      );
      expect(await project.list().isEmpty, isTrue);
      session = api.accept(
        session.id,
        session.hypotheses.first.id,
        'engineer confirmed',
      );
      expect(api.analytics(session.id).accepted, 1);
      session = api.rollback(session.id, 0);
      session = api.reject(
        session.id,
        session.hypotheses.first.id,
        'engineer rejected',
      );
      expect(api.analytics(session.id).rejected, 1);
      expect(session.dna.predominantFeatures, isNotEmpty);
      await api.persist(session.id);
      for (final path in EngineeringFeatureRepository.paths) {
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
          primitiveMap = <String, dynamic>{},
          ai = <String, dynamic>{},
          workspace = <String, dynamic>{},
          inspector = <String, dynamic>{},
          analytics = <String, dynamic>{};
      final integration = OfficialEngineeringFeatureIntegration(
        project: projectMap,
        primitiveIntelligence: primitiveMap,
        aiFoundation: ai,
        workspace: workspace,
        propertyInspector: inspector,
        analytics: analytics,
      );
      final api = const EngineeringFeatureIntelligenceFactory().create(
        projectDirectory: project,
        integration: integration,
      );
      final session = api.analyze(
        sessionId: 'integrated',
        primitives: primitives(project, 'integrated', [
          observation(
            'bearing',
            featureCode: EngineeringFeatureType.bearingSeat.index,
          ),
        ]),
      );
      final ui = EngineeringFeatureWorkspace(
        session: session,
        recommendations: api.recommendations(session.id),
        analytics: api.analytics(session.id),
      );
      expect(integration.graph.isComplete, isTrue);
      expect(ai['engineeringDna'], isNotNull);
      expect(ui.propertyInspector['Panel'], 'Engineering Features');
      expect(ui.propertyInspector['Feature Tree'], isNotNull);
      expect(ui.propertyInspector['Primitive Tree'], isNotEmpty);
      expect(ui.propertyInspector['Suggested Strategy'], isNotNull);
      expect(ui.propertyInspector['Geometry Modified'], isFalse);
    },
  );

  test('1,000 complete pipelines are reproducible', () {
    final values = [observation('c1'), observation('c2')];
    for (var index = 0; index < 1000; index++) {
      final sourceA = primitives(project, 'project-$index', values);
      final sourceB = primitives(
        project,
        'project-$index',
        values.reversed.toList(),
      );
      final first = const EngineeringFeatureIntelligenceFactory().create(
        projectDirectory: project,
      );
      final second = const EngineeringFeatureIntelligenceFactory().create(
        projectDirectory: project,
      );
      final a = first.analyze(
        sessionId: 'pipeline-$index',
        primitives: sourceA,
      );
      final b = second.analyze(
        sessionId: 'pipeline-$index',
        primitives: sourceB,
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
