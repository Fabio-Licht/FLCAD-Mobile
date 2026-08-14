import '../models/surface_topology_models.dart';

abstract interface class SurfaceTopologyIntegration {
  void onTopologyBuilt(SurfaceTopologyReport report);
}

class OfficialSurfaceTopologyIntegration implements SurfaceTopologyIntegration {
  OfficialSurfaceTopologyIntegration({
    required this.project,
    required this.dashboard,
    required this.session,
  });
  final Map<String, dynamic> project, dashboard, session;
  @override
  void onTopologyBuilt(SurfaceTopologyReport report) {
    final projection = {
      'reportId': report.id,
      'patches': report.patches.map((e) => e.toJson()).toList(),
      'boundaries': report.boundaries.map((e) => e.toJson()).toList(),
      'loops': report.loops.map((e) => e.toJson()).toList(),
      'intersections': report.intersections.map((e) => e.toJson()).toList(),
      'graph': report.graph.toJson(),
      'analytics': report.analytics.toJson(),
    };
    project['surfaceTopology'] = projection;
    project['engineeringStudio'] = {
      ...(project['engineeringStudio'] as Map<String, dynamic>? ?? {}),
      'topologyWorkspace': true,
      'patchTree': projection['patches'],
      'topologyGraph': projection['graph'],
    };
    project['engineeringIntelligence'] = {
      ...(project['engineeringIntelligence'] as Map<String, dynamic>? ?? {}),
      'topologyAdvisor': report.advice.map((e) => e.toJson()).toList(),
      'automaticActions': false,
    };
    project['interactiveReverse'] = {
      ...(project['interactiveReverse'] as Map<String, dynamic>? ?? {}),
      'topology': projection,
      'selectionAvailable': true,
    };
    project['liveValidation'] = {
      'topologyHealth': report.patches.map((e) => e.health.name).toList(),
      'automaticExecution': false,
    };
    dashboard['surfaceTopology'] = projection;
    session['surfaceTopology'] = projection;
    session['workflowStage'] = 'surfaceTopology';
    session['history'] = [
      ...(session['history'] as List? ?? const []),
      {'operation': 'Build Surface Topology', 'result': report.id},
    ];
  }
}
