import '../reports/certification_models.dart';

class CertificationDiagnostics {
  const CertificationDiagnostics();
  List<String> inspect(List<CertificationCheck> checks) => [
    for (final check in checks)
      if (check.status != CertificationStatus.passed)
        '${check.name}: ${check.evidence}',
  ];
}
