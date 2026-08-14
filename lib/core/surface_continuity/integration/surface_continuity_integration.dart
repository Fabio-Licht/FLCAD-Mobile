import '../models/surface_continuity_models.dart';

abstract interface class SurfaceContinuityIntegration {
  void onQualityAnalyzed(SurfaceQualityReport report);
}

class OfficialSurfaceContinuityIntegration
    implements SurfaceContinuityIntegration {
  OfficialSurfaceContinuityIntegration({
    required this.project,
    required this.dashboard,
    required this.session,
  });
  final Map<String, dynamic> project, dashboard, session;
  @override
  void onQualityAnalyzed(SurfaceQualityReport report) {
    final projection = {
      'reportId': report.id,
      'quality': report.patchQualities.map((e) => e.toJson()).toList(),
      'continuity': report.continuity.map((e) => e.toJson()).toList(),
      'graph': report.graph.toJson(),
      'analytics': report.analytics.toJson(),
    };
    project['surfaceQuality'] = projection;
    project['engineeringStudio'] = {
      ...(project['engineeringStudio'] as Map<String, dynamic>? ?? {}),
      'surfaceQualityWorkspace': true,
      'continuityTree': projection['continuity'],
      'qualityInspector': true,
    };
    project['engineeringIntelligence'] = {
      ...(project['engineeringIntelligence'] as Map<String, dynamic>? ?? {}),
      'qualityAdvisor': report.advice.map((e) => e.toJson()).toList(),
      'automaticActions': false,
    };
    project['interactiveReverse'] = {
      ...(project['interactiveReverse'] as Map<String, dynamic>? ?? {}),
      'surfaceQuality': projection,
    };
    project['liveValidation'] = {
      'surfaceQuality': report.patchQualities
          .map(
            (e) => {
              'patchId': e.patch.id,
              'health': e.health.name,
              'score': e.overall,
            },
          )
          .toList(),
      'automaticExecution': false,
    };
    dashboard['surfaceQuality'] = projection;
    session['surfaceQuality'] = projection;
    session['workflowStage'] = 'surfaceQuality';
    session['history'] = [
      ...(session['history'] as List? ?? const []),
      {'operation': 'Surface Quality Analysis', 'result': report.id},
    ];
  }
}
