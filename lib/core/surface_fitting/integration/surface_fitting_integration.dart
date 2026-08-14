import '../models/surface_fitting_models.dart';

abstract interface class SurfaceFittingIntegration {
  void onSurfaceFittingCompleted(SurfaceFittingReport report);
}

class OfficialSurfaceFittingIntegration implements SurfaceFittingIntegration {
  OfficialSurfaceFittingIntegration({
    required this.project,
    required this.dashboard,
    required this.session,
  });
  final Map<String, dynamic> project, dashboard, session;
  @override
  void onSurfaceFittingCompleted(SurfaceFittingReport report) {
    final projection = {
      'reportId': report.id,
      'surfaces': report.surfaces.map((e) => e.toJson()).toList(),
      'analytics': report.analytics.toJson(),
      'tree': {for (final e in report.surfaces) e.id: e.toJson()},
      'selectedSurface': null,
      'highlightedSurface': null,
    };
    project['surfaceFitting'] = projection;
    project['surfaceRepositoryUpdated'] = true;
    project['engineeringStudio'] = {
      ...(project['engineeringStudio'] as Map<String, dynamic>? ?? {}),
      'surfaceFittingWorkspace': true,
      'surfaceTree': projection['tree'],
      'surfaceProperties': true,
    };
    project['engineeringIntelligence'] = {
      ...(project['engineeringIntelligence'] as Map<String, dynamic>? ?? {}),
      'surfaceAdvisor': report.advice.map((e) => e.toJson()).toList(),
      'automaticActions': false,
    };
    project['interactiveReverse'] = {
      ...(project['interactiveReverse'] as Map<String, dynamic>? ?? {}),
      'fittedSurfaces': projection,
      'selectionAvailable': true,
    };
    project['liveValidation'] = {
      'surfaceValidation': report.surfaces
          .map((e) => {'id': e.id, 'health': e.health.name})
          .toList(),
      'automaticExecution': false,
    };
    dashboard['surfaceFitting'] = projection;
    session['surfaceFitting'] = projection;
    session['workflowStage'] = 'surfaceFitting';
    session['history'] = [
      ...(session['history'] as List? ?? const []),
      {'operation': 'Surface Fitting', 'result': report.id},
    ];
  }
}
