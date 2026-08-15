import '../audit/professional_modeling_audit.dart';
import '../reports/professional_modeling_report.dart';

class ProfessionalModelingCertificationEngine {
  const ProfessionalModelingCertificationEngine(this.audit);
  final ProfessionalModelingAudit audit;
  ProfessionalModelingReport certify(ProfessionalModelingAuditInput input) {
    final findings = audit.evaluate(input);
    double score(String prefix) {
      final selected = findings
          .where((e) => e.name.startsWith(prefix))
          .toList();
      return selected.isEmpty
          ? 0
          : selected.where((e) => e.passed).length * 100 / selected.length;
    }

    final architecture = score('Architecture');
    final scores = ProfessionalModelingScores(
      architecture: architecture,
      geometry: score('Geometry'),
      runtime: score('Runtime'),
      workflow: score('Workflow'),
      modeling: _modelingScore(findings),
      manufacturing: score('Quality'),
    );
    final native = findings
        .firstWhere((e) => e.name == 'Native bearing.stl')
        .passed;
    final allPassed = findings.every((e) => e.passed) && scores.platform == 100;
    final status = allPassed
        ? ProfessionalCertificationStatus.approved
        : native
        ? ProfessionalCertificationStatus.rejected
        : ProfessionalCertificationStatus.requiresNativeRun;
    return ProfessionalModelingReport(
      status: status,
      scores: scores,
      findings: findings,
      pipelineCount: input.pipelines.length,
      previewCount: input.pipelines.where((e) => e.preview).length,
      validationCount: input.pipelines.where((e) => e.validation).length,
      rollbackCount: input.pipelines.where((e) => e.rollback).length,
      fixture: input.fixture,
      nativeBackend: input.nativeBackend,
      createdAt: DateTime.now().toUtc(),
    );
  }

  double _modelingScore(List<ProfessionalAuditFinding> findings) {
    final selected = findings
        .where(
          (e) => {
            'All modeling modules integrated',
            'Geometry preserved in every pipeline',
            'UnsupportedOperation diagnostics',
            '500 deterministic pipelines',
          }.contains(e.name),
        )
        .toList();
    return selected.where((e) => e.passed).length * 100 / selected.length;
  }
}
