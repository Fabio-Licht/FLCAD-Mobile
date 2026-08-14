import '../reports/certification_models.dart';

class ArchitectureChecks {
  static const modules = [
    'Recognition',
    'Reference',
    'Alignment',
    'Validation',
    'Workflow',
    'Adaptive Studio',
    'Interactive Reverse',
    'Sketch',
    'Constraint Solver',
    'Feature Modeling',
    'Extrude',
    'Revolve',
    'Transition Features',
    'Engineering Intelligence',
    'Session Manager',
    'Project First',
    'GeometryKernelAPI',
    'OpenCascade Adapter',
  ];
  static const invariants = [
    'No duplicate domains',
    'No improper singleton',
    'No automatic timer',
    'No automatic isolate',
    'No automatic worker',
    'No DLL during bootstrap',
    'No simulated geometry',
    'No production fallback',
    'No direct OpenCascade access',
    'No circular dependency',
    'No Project First violation',
  ];
  List<CertificationCheck> evaluate(Map<String, String> evidence) => [
    for (final name in [...modules, ...invariants])
      evidence[name] == null
          ? CertificationCheck(
              name: name,
              status: CertificationStatus.blocked,
              evidence: 'Evidence not supplied',
            )
          : CertificationCheck(
              name: name,
              status: CertificationStatus.passed,
              evidence: evidence[name]!,
            ),
  ];
}
