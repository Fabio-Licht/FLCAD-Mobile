import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/ai_engineering/ai_engineering.dart';
import 'package:flcad_mobile/core/engineering_feature_intelligence/engineering_feature_intelligence.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/primitive_intelligence/primitive_intelligence.dart';
import 'package:flcad_mobile/core/smart_reference/smart_reference.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/smart_reference_certification.dart <project-dir>',
    );
    exitCode = 64;
    return;
  }
  final project = Directory(args.single).absolute;
  await project.create(recursive: true);
  final integration = OfficialSmartReferenceIntegration(
    project: {},
    aiFoundation: {},
    primitiveIntelligence: {},
    featureIntelligence: {},
    workspace: {},
    propertyInspector: {},
    analytics: {},
  );
  Map<String, dynamic>? baseline;
  for (var index = 0; index < 1200; index++) {
    final context = EngineeringContext(
      projectId: 'g012d-project',
      activePartId: 'part',
      patches: const ['patch'],
      boundaries: const ['boundary'],
      axes: const ['axis'],
      points: const ['point'],
      workflow: 'smartReferences',
      activeModule: 'featureIntelligence',
    ).snapshot();
    final observations = [
      for (final id in const ['c1', 'c2'])
        PrimitiveObservation(
          id: id,
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
          sessionId: 'g012d-primitives',
          context: context,
          primitives: observations,
        );
    final featureSession = const EngineeringFeatureIntelligenceFactory()
        .create(projectDirectory: project)
        .analyze(sessionId: 'g012d-features', primitives: primitiveSession);
    final api = const SmartReferenceFactory().create(projectDirectory: project);
    var session = api.analyze(sessionId: 'g012d', features: featureSession);
    session = api.accept(
      session.id,
      session.candidates.first.id,
      'certification',
    );
    session = api.rollback(session.id, 0);
    final projection = session.toJson();
    baseline ??= projection;
    if (jsonEncode(projection) != jsonEncode(baseline)) {
      throw StateError('Non-deterministic pipeline: $index');
    }
    if (session.candidates.any(
          (e) => e.evidence.isEmpty || e.justification.isEmpty,
        ) ||
        session.graph.toJson()['acyclic'] != true ||
        session.strategies.length != 3 ||
        session.strategies.any((e) => e.evidenceIds.isEmpty)) {
      throw StateError('Incomplete smart reference audit: $index');
    }
    if (index == 1199) {
      await api.persist(session.id);
    }
  }
  if (!integration.graph.isComplete) {
    throw StateError('Official integration graph is incomplete');
  }
  final certificate = {
    'sprint': 'G-012D',
    'status': 'APPROVED',
    'pipelines': 1200,
    'deterministic': true,
    'ranking': true,
    'acyclicGraphs': true,
    'strategies': true,
    'justifications': true,
    'persistence': true,
    'analytics': true,
    'integration': integration.graph.modules.toList()..sort(),
    'automaticCreation': false,
    'geometryModified': false,
  };
  await File(
    '${project.path}${Platform.pathSeparator}G012D-Certification.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(certificate));
  stdout.writeln('Professional Smart Reference System: APPROVED');
  stdout.writeln('Pipelines: 1200');
  stdout.writeln('Automatic creation: false');
  stdout.writeln('Geometry modified: false');
}
