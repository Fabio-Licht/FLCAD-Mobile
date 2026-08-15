import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flcad_mobile/core/ai_engineering/ai_engineering.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/primitive_intelligence/primitive_intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

EngineeringContextSnapshot context(String id) => EngineeringContext(
  projectId: id,
  activePartId: 'part',
  workflow: 'primitiveIntelligence',
  activeModule: 'recognition',
).snapshot();

PrimitiveObservation primitive(
  String id,
  PrimitiveType type, {
  double rank = .5,
  double angle = .16,
  double? patternGroup,
}) {
  final radians = angle * math.pi / 180;
  return PrimitiveObservation(
    id: id,
    type: type,
    measures: {
      'area': type == PrimitiveType.plane ? 150 : 20,
      'radius': 5,
      'length': 20,
      'angleDegrees': 5,
      'coaxiality': .9,
      'symmetry': .8,
      'radialSymmetry': type == PrimitiveType.sphere ? .9 : 0,
      'importance': rank,
      'manufacturingRelevance': .8,
      'alignmentRelevance': .7,
      'reconstructionRelevance': .9,
      'patternGroup': ?patternGroup,
      if (patternGroup != null)
        'patternKind': PatternKind.linear.index.toDouble(),
      if (patternGroup != null) 'patternScore': .95,
    },
    vectors: {
      if (type == PrimitiveType.plane)
        'normal': [math.sin(radians), 0, math.cos(radians)],
      if (type != PrimitiveType.plane) 'axis': const [0, 0, 1],
      if (type == PrimitiveType.sphere) 'center': const [0, 0, 2],
    },
    adjacentIds: const ['neighbor'],
    recognitionConfidence: .92,
  );
}

void main() {
  late Directory project;
  setUp(
    () async =>
        project = await Directory.systemTemp.createTemp('flcad-primitive-'),
  );
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  test(
    'analyzes all professional primitive types with evidence and no mutation',
    () {
      final api = const PrimitiveIntelligenceFactory().create(
        projectDirectory: project,
      );
      final session = api.analyze(
        sessionId: 'all-types',
        context: context('project'),
        primitives: [
          primitive('plane', PrimitiveType.plane),
          primitive('cylinder', PrimitiveType.cylinder),
          primitive('cone', PrimitiveType.cone),
          primitive('sphere', PrimitiveType.sphere),
          primitive('torus', PrimitiveType.torus),
        ],
      );
      expect(session.hypotheses, hasLength(5));
      expect(session.hypotheses.every((e) => e.evidence.isNotEmpty), isTrue);
      expect(
        session.hypotheses.every((e) => e.justification.isNotEmpty),
        isTrue,
      );
      expect(session.toJson()['automaticCommands'], isFalse);
      expect(session.toJson()['geometryModified'], isFalse);
      expect(
        api
            .recommendations(session.id)
            .every((e) => e.toJson()['createsEntities'] == false),
        isTrue,
      );
    },
  );

  test(
    'plane alignment reports X Y Z deviations and suggests XY without applying it',
    () {
      final result = const AlignmentIntelligence().analyze(
        primitive('plane', PrimitiveType.plane),
      );
      expect(result.angularDeviation.keys, containsAll(['X', 'Y', 'Z']));
      expect(result.suggestedOrientation, 'parallel to XY plane');
      expect(result.angularError, closeTo(.16, 1e-9));
      expect(result.toJson()['applied'], isFalse);
    },
  );

  test(
    'classification, axes, symmetry, patterns and ranking are deterministic',
    () {
      final api = const PrimitiveIntelligenceFactory().create(
        projectDirectory: project,
      );
      final session = api.analyze(
        sessionId: 'reasoning',
        context: context('project'),
        primitives: [
          primitive('plane', PrimitiveType.plane, rank: .4),
          primitive('c1', PrimitiveType.cylinder, rank: .9, patternGroup: 1),
          primitive('c2', PrimitiveType.cylinder, rank: .8, patternGroup: 1),
          primitive('sphere', PrimitiveType.sphere, rank: .3),
        ],
      );
      expect(session.hypotheses.first.primitive.id, 'c1');
      expect(session.hypotheses.first.function, PrimitiveFunction.hole);
      expect(session.hypotheses.first.axis, isNotNull);
      expect(session.patterns.single.kind, PatternKind.linear);
      expect(
        session.hypotheses
            .singleWhere((e) => e.primitive.id == 'sphere')
            .symmetry
            ?.kind,
        SymmetryKind.radial,
      );
    },
  );

  test(
    'user decisions, rollback, analytics and Project First persistence work',
    () async {
      final api = const PrimitiveIntelligenceFactory().create(
        projectDirectory: project,
      );
      var session = api.analyze(
        sessionId: 'audit',
        context: context('project'),
        primitives: [primitive('p', PrimitiveType.plane)],
      );
      expect(await project.list().isEmpty, isTrue);
      session = api.accept(
        session.id,
        session.hypotheses.first.id,
        'confirmed',
      );
      expect(api.analytics(session.id).accepted, 1);
      session = api.rollback(session.id, 0);
      session = api.reject(
        session.id,
        session.hypotheses.first.id,
        'operator rejected',
      );
      expect(api.analytics(session.id).rejected, 1);
      await api.persist(session.id);
      for (final path in PrimitiveIntelligenceRepository.paths) {
        expect(
          Directory(
            '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
    },
  );

  test('official graph, AI Foundation and Property Inspector integrate', () {
    final projectMap = <String, dynamic>{},
        ai = <String, dynamic>{},
        workspace = <String, dynamic>{},
        inspector = <String, dynamic>{},
        analytics = <String, dynamic>{};
    final integration = OfficialPrimitiveIntelligenceIntegration(
      project: projectMap,
      aiFoundation: ai,
      workspace: workspace,
      propertyInspector: inspector,
      analytics: analytics,
    );
    final api = const PrimitiveIntelligenceFactory().create(
      projectDirectory: project,
      integration: integration,
    );
    final session = api.analyze(
      sessionId: 'integrated',
      context: context('project'),
      primitives: [primitive('p', PrimitiveType.plane)],
    );
    final ui = PrimitiveIntelligenceWorkspace(
      session: session,
      recommendations: api.recommendations(session.id),
      analytics: api.analytics(session.id),
    );
    expect(integration.graph.isComplete, isTrue);
    expect(ai['primitiveContext'], isNotNull);
    expect(ui.propertyInspector['Panel'], 'Primitive Intelligence');
    expect(ui.propertyInspector['References Used'], isNotEmpty);
    expect(ui.propertyInspector['Geometry Modified'], isFalse);
  });

  test('700 complete pipelines are byte-for-byte reproducible', () {
    for (var index = 0; index < 700; index++) {
      final values = [
        primitive('plane', PrimitiveType.plane),
        primitive('c1', PrimitiveType.cylinder, patternGroup: 1),
        primitive('c2', PrimitiveType.cylinder, patternGroup: 1),
      ];
      final first = const PrimitiveIntelligenceFactory().create(
        projectDirectory: project,
      );
      final second = const PrimitiveIntelligenceFactory().create(
        projectDirectory: project,
      );
      final a = first.analyze(
        sessionId: 'pipeline-$index',
        context: context('project-$index'),
        primitives: values,
      );
      final b = second.analyze(
        sessionId: 'pipeline-$index',
        context: context('project-$index'),
        primitives: values.reversed,
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
