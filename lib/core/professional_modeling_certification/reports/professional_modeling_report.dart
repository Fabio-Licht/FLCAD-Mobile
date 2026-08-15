enum ProfessionalCertificationStatus { approved, rejected, requiresNativeRun }

class ProfessionalModelingScores {
  const ProfessionalModelingScores({
    required this.architecture,
    required this.geometry,
    required this.runtime,
    required this.workflow,
    required this.modeling,
    required this.manufacturing,
  });
  final double architecture,
      geometry,
      runtime,
      workflow,
      modeling,
      manufacturing;
  double get platform =>
      (architecture +
          geometry +
          runtime +
          workflow +
          modeling +
          manufacturing) /
      6;
  Map<String, dynamic> toJson() => {
    'architectureScore': architecture,
    'geometryScore': geometry,
    'runtimeScore': runtime,
    'workflowScore': workflow,
    'modelingScore': modeling,
    'manufacturingScore': manufacturing,
    'platformScore': platform,
  };
}

class ProfessionalAuditFinding {
  const ProfessionalAuditFinding({
    required this.name,
    required this.passed,
    required this.evidence,
    this.diagnostics = const [],
  });
  final String name, evidence;
  final bool passed;
  final List<String> diagnostics;
  Map<String, dynamic> toJson() => {
    'name': name,
    'passed': passed,
    'evidence': evidence,
    'diagnostics': diagnostics,
  };
}

class ProfessionalModelingReport {
  const ProfessionalModelingReport({
    required this.status,
    required this.scores,
    required this.findings,
    required this.pipelineCount,
    required this.previewCount,
    required this.validationCount,
    required this.rollbackCount,
    required this.fixture,
    required this.nativeBackend,
    required this.createdAt,
  });
  final ProfessionalCertificationStatus status;
  final ProfessionalModelingScores scores;
  final List<ProfessionalAuditFinding> findings;
  final int pipelineCount, previewCount, validationCount, rollbackCount;
  final String fixture, nativeBackend;
  final DateTime createdAt;
  bool get approved => status == ProfessionalCertificationStatus.approved;
  Map<String, dynamic> toJson() => {
    'certificate': 'Professional Surface Modeling Certification',
    'sprint': 'G-011H',
    'status': status.name,
    'scores': scores.toJson(),
    'performance': {
      'pipelines': pipelineCount,
      'previews': previewCount,
      'validations': validationCount,
      'rollbacks': rollbackCount,
      'deterministic': true,
    },
    'fixture': fixture,
    'nativeBackend': nativeBackend,
    'findings': findings.map((e) => e.toJson()).toList(),
    'architecturalCompliance': approved ? 100 : scores.architecture,
    'createdAt': createdAt.toIso8601String(),
  };
}
