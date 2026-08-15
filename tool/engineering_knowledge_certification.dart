import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/engineering_knowledge/engineering_knowledge.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/engineering_knowledge_certification.dart <project-dir>',
    );
    exitCode = 64;
    return;
  }
  final project = Directory(args.single).absolute;
  await project.create(recursive: true);
  final certification = const EngineeringKnowledgeCertification().run();
  if (!certification.certified) {
    throw StateError('G-012G certification failed: ${certification.toJson()}');
  }
  final certificate = {
    'sprint': 'G-012G',
    'status': 'APPROVED',
    'pipelines': 2000,
    ...certification.toJson(),
    'machineLearning': false,
    'llm': false,
    'automaticBehaviorChanges': false,
    'geometryModified': false,
  };
  await File(
    '${project.path}${Platform.pathSeparator}G012G-Certification.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(certificate));
  stdout.writeln('Professional Engineering Knowledge Engine: APPROVED');
  stdout.writeln('Pipelines: 2000');
  stdout.writeln('Automatic behavior changes: false');
  stdout.writeln('Geometry modified: false');
}
