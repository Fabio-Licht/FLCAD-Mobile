import 'dart:convert';
import 'dart:io';
import 'package:flcad_mobile/core/professional_modeling_certification/audit/professional_modeling_audit.dart';
import 'package:flcad_mobile/core/professional_modeling_certification/engine/professional_modeling_certification_engine.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/professional_modeling_certification.dart <native-evidence.json> <project-dir>',
    );
    exitCode = 64;
    return;
  }
  final raw =
      jsonDecode(await File(args[0]).readAsString()) as Map<String, dynamic>;
  Map<String, bool> flags(String key) =>
      (raw[key] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(key, value == true),
      );
  final pipelines = (raw['pipelines'] as List<dynamic>? ?? const []).map((
    item,
  ) {
    final value = item as Map<String, dynamic>;
    return ModelingPipelineEvidence(
      id: value['id'] as String,
      module: value['module'] as String,
      preview: value['preview'] == true,
      validation: value['validation'] == true,
      commitAttempted: value['commitAttempted'] == true,
      rollback: value['rollback'] == true,
      originalHandle: value['originalHandle'] as String,
      finalHandle: value['finalHandle'] as String,
      diagnostic: value['diagnostic'] as String,
      geometryModified: value['geometryModified'] == true,
      fallbacks: value['fallbacks'] as int? ?? -1,
    );
  }).toList();
  final dependencies =
      (raw['dependencies'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
      );
  final input = ProfessionalModelingAuditInput(
    fixture: raw['fixture'] as String? ?? '',
    nativeBackend: raw['nativeBackend'] as String? ?? '',
    architectureEvidence: flags('architecture'),
    geometryEvidence: flags('geometry'),
    runtimeEvidence: flags('runtime'),
    workflowEvidence: flags('workflow'),
    workspaceEvidence: flags('workspaces'),
    persistenceEvidence: flags('persistence'),
    qualityEvidence: flags('quality'),
    dependencies: dependencies,
    pipelines: pipelines,
  );
  final report = const ProfessionalModelingCertificationEngine(
    ProfessionalModelingAudit(),
  ).certify(input);
  final directory = Directory(args[1]);
  await directory.create(recursive: true);
  await File(
    '${directory.path}${Platform.pathSeparator}ProfessionalModelingCertificate.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  stdout.writeln(
    'Professional Surface Modeling Certification: ${report.status.name}',
  );
  stdout.writeln('Platform Score: ${report.scores.platform}');
  if (!report.approved) exitCode = 2;
}
