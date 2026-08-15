import '../reports/professional_modeling_report.dart';

class ModelingPipelineEvidence {
  const ModelingPipelineEvidence({
    required this.id,
    required this.module,
    required this.preview,
    required this.validation,
    required this.commitAttempted,
    required this.rollback,
    required this.originalHandle,
    required this.finalHandle,
    required this.diagnostic,
    required this.geometryModified,
    required this.fallbacks,
  });
  final String id, module, originalHandle, finalHandle, diagnostic;
  final bool preview, validation, commitAttempted, rollback, geometryModified;
  final int fallbacks;
  bool get valid =>
      preview &&
      validation &&
      commitAttempted &&
      rollback &&
      originalHandle == finalHandle &&
      !geometryModified &&
      fallbacks == 0 &&
      diagnostic.startsWith('UnsupportedOperation:');
}

class ProfessionalModelingAuditInput {
  const ProfessionalModelingAuditInput({
    required this.fixture,
    required this.nativeBackend,
    required this.architectureEvidence,
    required this.geometryEvidence,
    required this.runtimeEvidence,
    required this.workflowEvidence,
    required this.workspaceEvidence,
    required this.persistenceEvidence,
    required this.qualityEvidence,
    required this.dependencies,
    required this.pipelines,
  });
  final String fixture, nativeBackend;
  final Map<String, bool> architectureEvidence,
      geometryEvidence,
      runtimeEvidence,
      workflowEvidence,
      workspaceEvidence,
      persistenceEvidence,
      qualityEvidence;
  final Map<String, List<String>> dependencies;
  final List<ModelingPipelineEvidence> pipelines;
}

class ProfessionalModelingAudit {
  const ProfessionalModelingAudit();
  static const modules = {
    'Morph',
    'Extend',
    'Reduce',
    'Fair',
    'Boundary',
    'Manufacturing',
    'Advanced Surface',
  };
  static const unsupported = {
    'Morph': 'UnsupportedOperation: moveBoundary',
    'Extend': 'UnsupportedOperation: moveBoundary',
    'Reduce': 'UnsupportedOperation: reduceSurface',
    'Fair': 'UnsupportedOperation: fairSurface',
    'Boundary': 'UnsupportedOperation: editBoundary',
    'Manufacturing': 'UnsupportedOperation: manufacturingSurface',
  };
  List<ProfessionalAuditFinding> evaluate(
    ProfessionalModelingAuditInput input,
  ) {
    final findings = <ProfessionalAuditFinding>[];
    void auditMap(
      String group,
      Map<String, bool> evidence,
      Set<String> required,
    ) {
      for (final name in required) {
        final passed = evidence[name] == true;
        findings.add(
          ProfessionalAuditFinding(
            name: '$group: $name',
            passed: passed,
            evidence: evidence.containsKey(name)
                ? '$passed'
                : 'Evidence not supplied',
          ),
        );
      }
    }

    auditMap('Architecture', input.architectureEvidence, const {
      'Project First',
      'Bootstrap passive',
      'Lazy loading',
      'Dependency graph',
      'GeometryKernelAPI only',
      'Bridge-only OpenCascade',
      'No duplicate modules',
    });
    auditMap('Geometry', input.geometryEvidence, const {
      'No simulated geometry',
      'No fallback',
      'No parallel STL parser',
      'No out-of-kernel mutation',
    });
    auditMap('Runtime', input.runtimeEvidence, const {
      'No timers',
      'No isolates',
      'No automatic workers',
      'Passive runtime',
    });
    auditMap('Workflow', input.workflowEvidence, const {
      'Workflow',
      'Session',
      'Analytics',
      'Advisor',
      'Undo',
      'Redo',
      'Live Reconstruction',
    });
    auditMap('Workspace', input.workspaceEvidence, const {
      'All workspaces',
      'Property Inspectors',
      'FEL',
    });
    auditMap('Persistence', input.persistenceEvidence, const {
      'All Project First repositories',
    });
    auditMap('Quality', input.qualityEvidence, const {
      'Reflection',
      'Zebra',
      'Heat Map',
      'Curvature',
      'Draft',
      'Manufacturing Analyzer',
    });
    final present = input.pipelines.map((e) => e.module).toSet();
    findings.add(
      ProfessionalAuditFinding(
        name: 'All modeling modules integrated',
        passed: present.containsAll(modules),
        evidence: present.join(', '),
      ),
    );
    final invalid = input.pipelines
        .where((e) => !e.valid)
        .map((e) => e.id)
        .toList();
    findings.add(
      ProfessionalAuditFinding(
        name: 'Geometry preserved in every pipeline',
        passed: invalid.isEmpty,
        evidence:
            '${input.pipelines.length - invalid.length}/${input.pipelines.length}',
        diagnostics: invalid,
      ),
    );
    final wrongUnsupported = input.pipelines
        .where((e) {
          final expected = unsupported[e.module];
          return expected != null && e.diagnostic != expected;
        })
        .map((e) => '${e.id}: ${e.diagnostic}')
        .toList();
    findings.add(
      ProfessionalAuditFinding(
        name: 'UnsupportedOperation diagnostics',
        passed: wrongUnsupported.isEmpty,
        evidence:
            '${input.pipelines.length - wrongUnsupported.length}/${input.pipelines.length}',
        diagnostics: wrongUnsupported,
      ),
    );
    final cycles = _cycles(input.dependencies);
    findings.add(
      ProfessionalAuditFinding(
        name: 'Dependency graph acyclic',
        passed: cycles.isEmpty,
        evidence: cycles.isEmpty ? 'No cycles' : cycles.join(', '),
        diagnostics: cycles,
      ),
    );
    findings.add(
      ProfessionalAuditFinding(
        name: 'Native bearing.stl',
        passed:
            input.fixture.toLowerCase().endsWith('bearing.stl') &&
            input.nativeBackend.startsWith('OpenCascade 8.0.1'),
        evidence: '${input.fixture}; ${input.nativeBackend}',
      ),
    );
    findings.add(
      ProfessionalAuditFinding(
        name: '500 deterministic pipelines',
        passed: input.pipelines.length >= 500,
        evidence: '${input.pipelines.length}/500',
      ),
    );
    return List.unmodifiable(findings);
  }

  List<String> _cycles(Map<String, List<String>> graph) {
    final visiting = <String>{}, visited = <String>{}, cycles = <String>[];
    void visit(String node) {
      if (visiting.contains(node)) {
        cycles.add(node);
        return;
      }
      if (!visited.add(node)) return;
      visiting.add(node);
      for (final dependency in graph[node] ?? const <String>[]) {
        visit(dependency);
      }
      visiting.remove(node);
    }

    for (final node in graph.keys) {
      visit(node);
    }
    return cycles;
  }
}
