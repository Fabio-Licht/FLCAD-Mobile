import 'dart:io';

import 'package:flcad_mobile/core/ai_platform_certification/ai_platform_certification.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/ai_platform_certification.dart <project-dir> <certification-date> <coverage>',
    );
    exitCode = 64;
    return;
  }
  final project = Directory(args[0]).absolute;
  final engine = const AIPlatformCertificationEngine();
  if (!engine.validateDeterminism(
    version: '1.0.0',
    certificationDate: args[1],
    coverage: args[2],
  )) {
    throw StateError('2,500 deterministic platform pipelines failed');
  }
  final certificate = engine.certify(
    version: '1.0.0',
    certificationDate: args[1],
    coverage: args[2],
  );
  final repository = PlatformCertificationRepository(project);
  final certificateFile = await repository.emit(certificate);
  final auditFile = await repository.emitAudit(certificate);
  stdout.writeln(
    'AI Engineering Platform G-012: ${certificate.status.name.toUpperCase()}',
  );
  stdout.writeln('Pipelines: ${certificate.pipelineCount}');
  stdout.writeln('Certificate: ${certificateFile.path}');
  stdout.writeln('Architecture audit: ${auditFile.path}');
  stdout.writeln('Geometry modified: false');
  stdout.writeln('Automatic decisions: false');
}
