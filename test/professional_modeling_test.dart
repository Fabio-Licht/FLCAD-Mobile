import 'package:flcad_mobile/core/professional_modeling_certification/audit/professional_modeling_audit.dart';
import 'package:flcad_mobile/core/professional_modeling_certification/engine/professional_modeling_certification_engine.dart';
import 'package:flcad_mobile/core/professional_modeling_certification/reports/professional_modeling_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const modules = [
    'Morph',
    'Extend',
    'Reduce',
    'Fair',
    'Boundary',
    'Manufacturing',
    'Advanced Surface',
  ];
  const diagnostics = {
    'Morph': 'UnsupportedOperation: moveBoundary',
    'Extend': 'UnsupportedOperation: moveBoundary',
    'Reduce': 'UnsupportedOperation: reduceSurface',
    'Fair': 'UnsupportedOperation: fairSurface',
    'Boundary': 'UnsupportedOperation: editBoundary',
    'Manufacturing': 'UnsupportedOperation: manufacturingSurface',
    'Advanced Surface': 'UnsupportedOperation: matchSurface',
  };
  test(
    '500 deterministic pipelines achieve approval only with complete native evidence',
    () {
      final pipelines = [
        for (var i = 0; i < 500; i++)
          ModelingPipelineEvidence(
            id: 'pipeline:$i',
            module: modules[i % modules.length],
            preview: true,
            validation: true,
            commitAttempted: true,
            rollback: true,
            originalHandle: 'native:$i',
            finalHandle: 'native:$i',
            diagnostic: diagnostics[modules[i % modules.length]]!,
            geometryModified: false,
            fallbacks: 0,
          ),
      ];
      final report = const ProfessionalModelingCertificationEngine(
        ProfessionalModelingAudit(),
      ).certify(_input(pipelines: pipelines));
      expect(report.status, ProfessionalCertificationStatus.approved);
      expect(report.scores.platform, 100);
      expect(report.previewCount, 500);
      expect(report.validationCount, 500);
      expect(report.rollbackCount, 500);
    },
  );
  test('missing native bearing evidence can never be approved', () {
    final report = const ProfessionalModelingCertificationEngine(
      ProfessionalModelingAudit(),
    ).certify(_input(fixture: '', backend: '', pipelines: const []));
    expect(report.status, ProfessionalCertificationStatus.requiresNativeRun);
    expect(report.approved, isFalse);
  });
  test('geometry mutation or fallback rejects certification', () {
    final pipelines = [
      for (var i = 0; i < 500; i++)
        ModelingPipelineEvidence(
          id: 'p:$i',
          module: modules[i % modules.length],
          preview: true,
          validation: true,
          commitAttempted: true,
          rollback: true,
          originalHandle: 'a',
          finalHandle: i == 0 ? 'b' : 'a',
          diagnostic: diagnostics[modules[i % modules.length]]!,
          geometryModified: i == 0,
          fallbacks: i == 0 ? 1 : 0,
        ),
    ];
    final report = const ProfessionalModelingCertificationEngine(
      ProfessionalModelingAudit(),
    ).certify(_input(pipelines: pipelines));
    expect(report.status, ProfessionalCertificationStatus.rejected);
  });
}

ProfessionalModelingAuditInput _input({
  String fixture = 'C:/native/bearing.stl',
  String backend = 'OpenCascade 8.0.1 Release',
  required List<ModelingPipelineEvidence> pipelines,
}) {
  const architecture = {
    'Project First': true,
    'Bootstrap passive': true,
    'Lazy loading': true,
    'Dependency graph': true,
    'GeometryKernelAPI only': true,
    'Bridge-only OpenCascade': true,
    'No duplicate modules': true,
  };
  return ProfessionalModelingAuditInput(
    fixture: fixture,
    nativeBackend: backend,
    architectureEvidence: architecture,
    geometryEvidence: const {
      'No simulated geometry': true,
      'No fallback': true,
      'No parallel STL parser': true,
      'No out-of-kernel mutation': true,
    },
    runtimeEvidence: const {
      'No timers': true,
      'No isolates': true,
      'No automatic workers': true,
      'Passive runtime': true,
    },
    workflowEvidence: const {
      'Workflow': true,
      'Session': true,
      'Analytics': true,
      'Advisor': true,
      'Undo': true,
      'Redo': true,
      'Live Reconstruction': true,
    },
    workspaceEvidence: const {
      'All workspaces': true,
      'Property Inspectors': true,
      'FEL': true,
    },
    persistenceEvidence: const {'All Project First repositories': true},
    qualityEvidence: const {
      'Reflection': true,
      'Zebra': true,
      'Heat Map': true,
      'Curvature': true,
      'Draft': true,
      'Manufacturing Analyzer': true,
    },
    dependencies: const {
      'Project': ['Workflow'],
      'Workflow': ['Surface Operations'],
      'Surface Operations': ['GeometryKernelAPI'],
      'GeometryKernelAPI': [],
    },
    pipelines: pipelines,
  );
}
