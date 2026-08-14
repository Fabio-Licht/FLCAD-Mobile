import 'dart:io';
import '../analytics/certification_analytics.dart';
import '../checks/architecture_checks.dart';
import '../diagnostics/certification_diagnostics.dart';
import '../history/certification_history.dart';
import '../reports/certification_models.dart';
import '../repository/platform_certification_repository.dart';
import '../../mesh_foundation/models/mesh_models.dart';

typedef DemonstrationStep = Future<void> Function();

class PlatformCertificationEngine {
  PlatformCertificationEngine({required this.repository});
  final PlatformCertificationRepository repository;
  final CertificationAnalytics analytics = CertificationAnalytics();
  final CertificationHistory history = CertificationHistory();
  final ArchitectureChecks architectureChecks = ArchitectureChecks();
  final CertificationDiagnostics diagnostics = const CertificationDiagnostics();

  static const demonstrationSteps = [
    'Open STL',
    'Select region',
    'Recognition',
    'Create Datum Plane',
    'Create Datum Axis',
    'Alignment',
    'Create Sketch',
    'Create Extrude',
    'Update Validation',
    'Engineering Review',
    'Save Session',
    'Close Project',
    'Reopen Project',
    'Restore Session',
    'Final Validation',
    'Project Complete',
  ];

  List<CertificationCheck> certifyMeshFoundation({
    required MeshEntity mesh,
    required Map<String, dynamic> project,
    required Map<String, dynamic> workflow,
    required Map<String, dynamic> session,
    required Map<String, dynamic> dashboard,
  }) => [
    CertificationCheck(
      name: 'Open bearing.stl',
      status:
          mesh.sourceFile.toLowerCase().endsWith('bearing.stl') &&
              mesh.triangleCount > 0
          ? CertificationStatus.passed
          : CertificationStatus.failed,
      evidence: '${mesh.sourceFile}; ${mesh.triangleCount} triangles',
    ),
    CertificationCheck(
      name: 'Register MeshEntity',
      status: mesh.id.isNotEmpty && mesh.kernelHandle.kernelId == 'opencascade'
          ? CertificationStatus.passed
          : CertificationStatus.failed,
      evidence: mesh.id,
    ),
    CertificationCheck(
      name: 'Update Workflow',
      status: workflow['currentIndex'] == 1
          ? CertificationStatus.passed
          : CertificationStatus.failed,
      evidence: workflow.toString(),
    ),
    CertificationCheck(
      name: 'Update Session',
      status: session['mesh'] != null
          ? CertificationStatus.passed
          : CertificationStatus.failed,
      evidence: 'session mesh=${session['mesh'] != null}',
    ),
    CertificationCheck(
      name: 'Update Dashboard',
      status:
          dashboard['mesh'] != null && dashboard['recognitionStarted'] == false
          ? CertificationStatus.passed
          : CertificationStatus.failed,
      evidence:
          'mesh visible; recognitionStarted=${dashboard['recognitionStarted']}',
    ),
    CertificationCheck(
      name: 'Update Project',
      status: project['activeMesh'] != null
          ? CertificationStatus.passed
          : CertificationStatus.failed,
      evidence: 'activeMesh=${project['activeMesh'] != null}',
    ),
  ];

  Future<DemonstrationResult> demonstrate({
    required String partPath,
    required Map<String, DemonstrationStep> steps,
  }) async {
    final file = File(partPath),
        results = <CertificationCheck>[],
        failures = <String>[];
    if (!await file.exists() || await file.length() == 0) {
      final result = DemonstrationResult(
        partPath: partPath,
        steps: const [],
        status: CertificationStatus.blocked,
        diagnostics: ['A real, non-empty STL file is required'],
      );
      history.demonstrations.add(result);
      return result;
    }
    for (final name in demonstrationSteps) {
      final operation = steps[name];
      if (operation == null) {
        results.add(
          CertificationCheck(
            name: name,
            status: CertificationStatus.blocked,
            evidence: 'Official API step not supplied',
          ),
        );
        failures.add('$name was not executed');
        continue;
      }
      try {
        await operation();
        results.add(
          CertificationCheck(
            name: name,
            status: CertificationStatus.passed,
            evidence: 'Official API completed for ${file.path}',
          ),
        );
      } catch (error) {
        results.add(
          CertificationCheck(
            name: name,
            status: CertificationStatus.failed,
            evidence: error.toString(),
          ),
        );
        failures.add('$name: $error');
      }
    }
    final status = results.every((e) => e.status == CertificationStatus.passed)
        ? CertificationStatus.passed
        : results.any((e) => e.status == CertificationStatus.failed)
        ? CertificationStatus.failed
        : CertificationStatus.blocked;
    final result = DemonstrationResult(
      partPath: partPath,
      steps: results,
      status: status,
      diagnostics: failures,
    );
    history.demonstrations.add(result);
    analytics.demonstrations++;
    return result;
  }

  CertificationReport certify({
    required Map<String, String> evidence,
    required DemonstrationResult? demonstration,
    EngineeringAudit? audit,
  }) {
    final checks = architectureChecks.evaluate(evidence),
        passRate =
            checks.where((e) => e.status == CertificationStatus.passed).length /
            checks.length *
            100;
    double domainScore(Iterable<String> names) {
      final selected = checks.where((e) => names.contains(e.name)).toList();
      return selected.isEmpty
          ? passRate
          : selected
                    .where((e) => e.status == CertificationStatus.passed)
                    .length /
                selected.length *
                100;
    }

    final scores = PlatformScores(
      architecture: domainScore(ArchitectureChecks.invariants),
      workflow: domainScore(const ['Workflow', 'Session Manager']),
      integration: domainScore(ArchitectureChecks.modules),
      validation: domainScore(const ['Validation', 'Project First']),
      ux: domainScore(const ['Adaptive Studio', 'Interactive Reverse']),
      performance: demonstration?.status == CertificationStatus.passed
          ? 100
          : 0,
      stability: passRate,
      maintainability: domainScore(ArchitectureChecks.invariants),
      engineering: domainScore(const [
        'Engineering Intelligence',
        'Feature Modeling',
        'GeometryKernelAPI',
      ]),
    );
    final resolvedAudit =
        audit ??
        EngineeringAudit(
          strengths: [
            if (passRate == 100) 'All supplied architecture checks passed',
          ],
          weaknesses: diagnostics.inspect(checks),
          couplings: const ['Workflow → GeometryKernelAPI'],
          duplications: const [],
          suggestedImprovements: [
            if (demonstration?.status != CertificationStatus.passed)
              'Complete the real-part demonstration',
          ],
          readyForG010: [
            if (checks.every((e) => e.status == CertificationStatus.passed) &&
                demonstration?.status == CertificationStatus.passed)
              'Surface Reconstruction',
          ],
          blockers: [
            if (demonstration == null ||
                demonstration.status != CertificationStatus.passed)
              'Real end-to-end demonstration is incomplete',
          ],
        );
    final report = CertificationReport(
      checks: checks,
      scores: scores,
      audit: resolvedAudit,
      demonstration: demonstration,
    );
    history.reports.add(report);
    analytics.certifications++;
    return report;
  }

  Future<void> persist() => repository.save(
    reports: history.reports,
    demonstrations: history.demonstrations,
    analytics: analytics,
  );
}
