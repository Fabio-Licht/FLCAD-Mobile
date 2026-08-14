import '../../utils/id_generator.dart';

enum CertificationStatus { pending, passed, failed, blocked }

class CertificationCheck {
  const CertificationCheck({
    required this.name,
    required this.status,
    required this.evidence,
    this.diagnostics = const [],
  });
  final String name, evidence;
  final CertificationStatus status;
  final List<String> diagnostics;
  Map<String, dynamic> toJson() => {
    'name': name,
    'status': status.name,
    'evidence': evidence,
    'diagnostics': diagnostics,
  };
}

class PlatformScores {
  const PlatformScores({
    required this.architecture,
    required this.workflow,
    required this.integration,
    required this.validation,
    required this.ux,
    required this.performance,
    required this.stability,
    required this.maintainability,
    required this.engineering,
  });
  final double architecture,
      workflow,
      integration,
      validation,
      ux,
      performance,
      stability,
      maintainability,
      engineering;
  double get overall =>
      (architecture +
          workflow +
          integration +
          validation +
          ux +
          performance +
          stability +
          maintainability +
          engineering) /
      9;
  Map<String, dynamic> toJson() => {
    'architectureScore': architecture,
    'workflowScore': workflow,
    'integrationScore': integration,
    'validationScore': validation,
    'uxScore': ux,
    'performanceScore': performance,
    'stabilityScore': stability,
    'maintainabilityScore': maintainability,
    'engineeringScore': engineering,
    'overallPlatformScore': overall,
  };
}

class EngineeringAudit {
  const EngineeringAudit({
    this.strengths = const [],
    this.weaknesses = const [],
    this.couplings = const [],
    this.duplications = const [],
    this.suggestedImprovements = const [],
    this.readyForG010 = const [],
    this.blockers = const [],
  });
  final List<String> strengths,
      weaknesses,
      couplings,
      duplications,
      suggestedImprovements,
      readyForG010,
      blockers;
  Map<String, dynamic> toJson() => {
    'strengths': strengths,
    'weaknesses': weaknesses,
    'couplings': couplings,
    'duplications': duplications,
    'suggestedImprovements': suggestedImprovements,
    'readyForG010': readyForG010,
    'blockers': blockers,
  };
}

class DemonstrationResult {
  DemonstrationResult({
    required this.partPath,
    required this.steps,
    required this.status,
    required this.diagnostics,
    String? id,
  }) : id = id ?? 'platform-demo:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id, partPath;
  final List<CertificationCheck> steps;
  final CertificationStatus status;
  final List<String> diagnostics;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'partPath': partPath,
    'steps': steps.map((e) => e.toJson()).toList(),
    'status': status.name,
    'diagnostics': diagnostics,
    'timestamp': timestamp.toIso8601String(),
  };
}

class CertificationReport {
  CertificationReport({
    required this.checks,
    required this.scores,
    required this.audit,
    required this.demonstration,
    String? id,
  }) : id = id ?? 'certification:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id;
  final List<CertificationCheck> checks;
  final PlatformScores scores;
  final EngineeringAudit audit;
  final DemonstrationResult? demonstration;
  final DateTime timestamp;
  CertificationStatus get status =>
      checks.any((e) => e.status == CertificationStatus.failed)
      ? CertificationStatus.failed
      : checks.any((e) => e.status != CertificationStatus.passed) ||
            demonstration?.status != CertificationStatus.passed
      ? CertificationStatus.blocked
      : CertificationStatus.passed;
  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.name,
    'checks': checks.map((e) => e.toJson()).toList(),
    'scores': scores.toJson(),
    'audit': audit.toJson(),
    'demonstration': demonstration?.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };
}
