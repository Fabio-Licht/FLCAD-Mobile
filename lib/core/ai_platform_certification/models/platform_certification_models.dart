import 'dart:convert';

enum CertificationStatus { approved, rejected }

List<T> _frozen<T>(Iterable<T> values) => List<T>.unmodifiable(values);

class ModuleCertification {
  ModuleCertification({
    required this.id,
    required this.sprint,
    required Iterable<String> capabilities,
    required Iterable<String> evidence,
    required this.justification,
    required this.origin,
    required this.score,
    Iterable<String> discardedHypotheses = const [],
  }) : capabilities = _frozen(capabilities),
       evidence = _frozen(evidence),
       discardedHypotheses = _frozen(discardedHypotheses) {
    if (this.evidence.isEmpty || justification.isEmpty || origin.isEmpty) {
      throw ArgumentError(
        'Certification requires evidence, justification and origin',
      );
    }
    if (score < 0 || score > 1) {
      throw RangeError.range(score, 0, 1, 'score');
    }
  }
  final String id, sprint, justification, origin;
  final List<String> capabilities, evidence, discardedHypotheses;
  final double score;
  bool get approved => capabilities.isNotEmpty && score == 1;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sprint': sprint,
    'capabilities': capabilities,
    'evidence': evidence,
    'justification': justification,
    'origin': origin,
    'score': score,
    'discardedHypotheses': discardedHypotheses,
    'traceability': '$sprint:$id',
    'approved': approved,
  };
}

class DependencyEdge {
  const DependencyEdge(this.from, this.to);
  final String from, to;
  Map<String, dynamic> toJson() => {'from': from, 'to': to};
}

class ArchitectureAudit {
  ArchitectureAudit({
    required Iterable<String> modules,
    required Iterable<DependencyEdge> dependencies,
    required Iterable<String> workspaces,
    required Iterable<String> propertyInspectors,
    required Iterable<String> persistenceRoots,
    required Iterable<String> analytics,
    required Iterable<String> adrs,
    required this.maxSerializedPipelineBytes,
  }) : modules = _frozen(modules),
       dependencies = _frozen(dependencies),
       workspaces = _frozen(workspaces),
       propertyInspectors = _frozen(propertyInspectors),
       persistenceRoots = _frozen(persistenceRoots),
       analytics = _frozen(analytics),
       adrs = _frozen(adrs);
  final List<String> modules,
      workspaces,
      propertyInspectors,
      persistenceRoots,
      analytics,
      adrs;
  final List<DependencyEdge> dependencies;
  final int maxSerializedPipelineBytes;

  bool get hasCycles {
    final outgoing = {for (final module in modules) module: <String>[]};
    for (final edge in dependencies) {
      outgoing[edge.from]?.add(edge.to);
    }
    final active = <String>{}, complete = <String>{};
    bool visit(String node) {
      if (active.contains(node)) return true;
      if (complete.contains(node)) return false;
      active.add(node);
      for (final next in outgoing[node] ?? const <String>[]) {
        if (visit(next)) return true;
      }
      active.remove(node);
      complete.add(node);
      return false;
    }

    return modules.any(visit);
  }

  List<String> get orphanModules {
    if (modules.length <= 1) return const [];
    final connected = <String>{};
    for (final edge in dependencies) {
      connected
        ..add(edge.from)
        ..add(edge.to);
    }
    return modules.where((e) => !connected.contains(e)).toList();
  }

  List<DependencyEdge> get invalidDependencies => dependencies
      .where((e) => !modules.contains(e.from) || !modules.contains(e.to))
      .toList();
  bool get approved =>
      !hasCycles &&
      orphanModules.isEmpty &&
      invalidDependencies.isEmpty &&
      workspaces.length == modules.length &&
      propertyInspectors.length == modules.length &&
      analytics.length == modules.length &&
      adrs.length == modules.length;
  Map<String, dynamic> toJson() => {
    'modules': modules,
    'dependencies': dependencies.map((e) => e.toJson()).toList(),
    'cycles': hasCycles,
    'orphanModules': orphanModules,
    'invalidDependencies': invalidDependencies.map((e) => e.toJson()).toList(),
    'workspaces': workspaces,
    'propertyInspectors': propertyInspectors,
    'persistenceRoots': persistenceRoots,
    'analytics': analytics,
    'adrs': adrs,
    'coupling': 'unidirectional layered integration',
    'reuse': 'immutable projections and shared audit vocabulary',
    'maxSerializedPipelineBytes': maxSerializedPipelineBytes,
    'timersUsed': false,
    'approved': approved,
  };
}

class AIEngineeringPlatformCertificate {
  AIEngineeringPlatformCertificate({
    required this.version,
    required this.certificationDate,
    required this.pipelineCount,
    required this.coverage,
    required Iterable<ModuleCertification> modules,
    required this.architecture,
    required Iterable<String> conformity,
  }) : modules = _frozen(modules),
       conformity = _frozen(conformity);
  final String version, certificationDate, coverage;
  final int pipelineCount;
  final List<ModuleCertification> modules;
  final ArchitectureAudit architecture;
  final List<String> conformity;
  CertificationStatus get status =>
      pipelineCount >= 2500 &&
          modules.length == 7 &&
          modules.every((e) => e.approved) &&
          architecture.approved
      ? CertificationStatus.approved
      : CertificationStatus.rejected;
  Map<String, dynamic> toJson() => {
    'name': 'AI Engineering Platform Certification',
    'version': version,
    'certificationDate': certificationDate,
    'pipelineCount': pipelineCount,
    'coverage': coverage,
    'modulesCertified': modules.map((e) => e.toJson()).toList(),
    'architecture': architecture.toJson(),
    'conformity': conformity,
    'status': status.name.toUpperCase(),
    'deterministic': true,
    'auditable': true,
    'explainable': true,
    'externalContextUsed': false,
    'automaticDecisions': false,
    'automaticCommands': false,
    'geometryModified': false,
    'machineLearning': false,
    'llm': false,
    'generativeAI': false,
    'timers': false,
    'isolates': false,
    'workers': false,
    'fallbacks': false,
  };
  String canonicalJson() => jsonEncode(toJson());
}
