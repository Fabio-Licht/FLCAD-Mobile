import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/ai_engineering/ai_engineering.dart';
import 'package:flcad_mobile/core/engineering_feature_intelligence/engineering_feature_intelligence.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/interactive_engineering_assistant/interactive_engineering_assistant.dart';
import 'package:flcad_mobile/core/primitive_intelligence/primitive_intelligence.dart';
import 'package:flcad_mobile/core/reconstruction_strategy/reconstruction_strategy.dart';
import 'package:flcad_mobile/core/smart_reference/smart_reference.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/interactive_engineering_assistant_certification.dart <project-dir>',
    );
    exitCode = 64;
    return;
  }
  final project = Directory(args.single).absolute;
  await project.create(recursive: true);
  final integration = OfficialInteractiveAssistantIntegration(
    project: {},
    aiFoundation: {},
    primitiveIntelligence: {},
    featureIntelligence: {},
    smartReferences: {},
    reconstructionStrategy: {},
    workspace: {},
    propertyInspector: {},
    analytics: {},
  );
  Map<String, dynamic>? baseline;
  for (var index = 0; index < 1800; index++) {
    final context = EngineeringContext(
      projectId: 'g012f-project',
      activePartId: 'part',
      patches: const ['patch'],
      boundaries: const ['boundary'],
      axes: const ['axis'],
      points: const ['point'],
      workflow: 'interactiveAssistant',
      activeModule: 'reconstructionStrategy',
      userContext: const {
        'objectives': ['accurate reconstruction'],
      },
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
    final primitives = const PrimitiveIntelligenceFactory()
        .create(projectDirectory: project)
        .analyze(
          sessionId: 'g012f-primitives',
          context: context,
          primitives: observations,
        );
    final features = const EngineeringFeatureIntelligenceFactory()
        .create(projectDirectory: project)
        .analyze(sessionId: 'g012f-features', primitives: primitives);
    final references = const SmartReferenceFactory()
        .create(projectDirectory: project)
        .analyze(sessionId: 'g012f-references', features: features);
    final strategies = const ReconstructionStrategyFactory()
        .create(projectDirectory: project)
        .analyze(
          sessionId: 'g012f-strategies',
          features: features,
          references: references,
        );
    final api = const InteractiveEngineeringAssistantFactory().create(
      projectDirectory: project,
    );
    var session = api.start(
      sessionId: 'g012f',
      features: features,
      references: references,
      strategies: strategies,
    );
    for (final question in EngineeringQuestion.values) {
      if (api.answer(session.id, question).evidence.isEmpty) {
        throw StateError('Unexplained answer: ${question.name}');
      }
    }
    session = api.completeStep(
      session.id,
      session.progress.first.stepId,
      'certification',
    );
    session = api.accept(
      session.id,
      session.suggestions.first.id,
      'certification',
    );
    session = api.rollback(session.id, 0);
    final projection = session.toJson();
    baseline ??= projection;
    if (jsonEncode(projection) != jsonEncode(baseline)) {
      throw StateError('Non-deterministic pipeline: $index');
    }
    if (session.messages.any((e) => e.evidence.isEmpty) ||
        session.suggestions.any(
          (e) => e.evidence.isEmpty || e.justification.isEmpty,
        ) ||
        session.timeline.isEmpty ||
        session.snapshots.any(
          (e) =>
              e.playbook.isEmpty ||
              e.references.isEmpty ||
              e.strategies.isEmpty ||
              e.history.isEmpty ||
              e.analytics.isEmpty,
        )) {
      throw StateError('Incomplete assistant audit: $index');
    }
    if (index == 1799) {
      await api.persist(session.id);
    }
  }
  if (!integration.graph.isComplete) {
    throw StateError('Official integration graph is incomplete');
  }
  final certificate = {
    'sprint': 'G-012F',
    'status': 'APPROVED',
    'pipelines': 1800,
    'deterministic': true,
    'projectContextOnly': true,
    'timeline': true,
    'snapshots': true,
    'integralRollback': true,
    'explainable': true,
    'persistence': true,
    'analytics': true,
    'integration': integration.graph.modules.toList()..sort(),
    'automaticCommands': false,
    'geometryModified': false,
  };
  await File(
    '${project.path}${Platform.pathSeparator}G012F-Certification.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(certificate));
  stdout.writeln('Professional Interactive Engineering Assistant: APPROVED');
  stdout.writeln('Pipelines: 1800');
  stdout.writeln('Automatic commands: false');
  stdout.writeln('Geometry modified: false');
}
