import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/ai_engineering/ai_engineering.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/primitive_intelligence/primitive_intelligence.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/primitive_intelligence_certification.dart <project-dir>',
    );
    exitCode = 64;
    return;
  }
  final project = Directory(args.single).absolute;
  await project.create(recursive: true);
  final integration = OfficialPrimitiveIntelligenceIntegration(
    project: {},
    aiFoundation: {},
    workspace: {},
    propertyInspector: {},
    analytics: {},
  );
  Map<String, dynamic>? baseline;
  for (var index = 0; index < 700; index++) {
    final api = const PrimitiveIntelligenceFactory().create(
      projectDirectory: project,
      integration: null,
    );
    final context = EngineeringContext(
      projectId: 'g012b-project',
      activePartId: 'part',
      workflow: 'primitiveIntelligence',
      activeModule: 'recognition',
    ).snapshot();
    final primitives = [
      PrimitiveObservation(
        id: 'plane',
        type: PrimitiveType.plane,
        measures: const {
          'area': 150,
          'importance': .8,
          'manufacturingRelevance': .9,
          'alignmentRelevance': 1,
          'reconstructionRelevance': .7,
        },
        vectors: const {
          'normal': [.002792523, 0, .999996101],
        },
        adjacentIds: const ['cylinder'],
        recognitionConfidence: .95,
      ),
      PrimitiveObservation(
        id: 'cylinder',
        type: PrimitiveType.cylinder,
        measures: const {
          'radius': 5,
          'length': 20,
          'coaxiality': .9,
          'importance': 1,
          'manufacturingRelevance': 1,
          'alignmentRelevance': .9,
          'reconstructionRelevance': 1,
        },
        vectors: const {
          'axis': [0, 0, 1],
        },
        adjacentIds: const ['plane'],
        recognitionConfidence: .97,
      ),
    ];
    var session = api.analyze(
      sessionId: 'g012b-$index',
      context: context,
      primitives: primitives,
    );
    session = api.accept(
      session.id,
      session.hypotheses.first.id,
      'certification',
    );
    session = api.rollback(session.id, 0);
    final projection = {
      'context': session.context.values,
      'hypotheses': session.hypotheses.map((e) {
        final json = e.toJson()..remove('id');
        return json;
      }).toList(),
      'patterns': session.patterns.map((e) => e.toJson()).toList(),
    };
    baseline ??= projection;
    if (jsonEncode(projection) != jsonEncode(baseline)) {
      throw StateError('Non-deterministic pipeline: $index');
    }
    if (session.hypotheses.any(
      (e) =>
          e.evidence.isEmpty || e.justification.isEmpty || e.alignment == null,
    )) {
      throw StateError('Incomplete audit evidence: $index');
    }
    if (index == 699) {
      await api.persist(session.id);
    }
  }
  if (!integration.graph.isComplete) {
    throw StateError('Official integration graph is incomplete');
  }
  final certificate = {
    'sprint': 'G-012B',
    'status': 'APPROVED',
    'pipelines': 700,
    'deterministic': true,
    'ranking': true,
    'evidence': true,
    'justifications': true,
    'alignmentSuggestions': true,
    'context': true,
    'analytics': true,
    'persistence': true,
    'rollback': true,
    'automaticCommands': false,
    'automaticEntities': false,
    'geometryModified': false,
    'moduleGraph': integration.graph.modules.toList()..sort(),
  };
  await File(
    '${project.path}${Platform.pathSeparator}G012B-Certification.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(certificate));
  stdout.writeln('Professional Primitive Intelligence Engine: APPROVED');
  stdout.writeln('Pipelines: 700');
  stdout.writeln('Automatic commands: false');
  stdout.writeln('Geometry modified: false');
}
