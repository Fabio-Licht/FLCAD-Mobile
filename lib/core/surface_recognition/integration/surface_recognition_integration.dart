import '../models/surface_recognition_models.dart';

abstract interface class SurfaceRecognitionIntegration {
  void onRecognitionCompleted(SurfaceRecognitionReport report);
}

class OfficialSurfaceRecognitionIntegration
    implements SurfaceRecognitionIntegration {
  OfficialSurfaceRecognitionIntegration({
    required this.project,
    required this.dashboard,
    required this.session,
  });
  final Map<String, dynamic> project, dashboard, session;
  @override
  void onRecognitionCompleted(SurfaceRecognitionReport report) {
    final projection = {
      'reportId': report.id,
      'meshId': report.meshId,
      'regionCount': report.classifications.length,
      'averageConfidence': report.analytics.averageConfidence,
      'tree': {for (final c in report.classifications) c.region.id: c.toJson()},
      'confidenceMap': {
        for (final c in report.classifications) c.region.id: c.confidence,
      },
      'selectedRegion': null,
      'highlightedRegion': null,
    };
    project['surfaceRecognition'] = projection;
    project['recognitionReport'] = report.toJson();
    project['engineeringIntelligence'] = {
      'recognitionReady': true,
      'advisor': report.advice.map((e) => e.toJson()).toList(),
      'automaticActions': false,
    };
    project['engineeringStudio'] = {
      ...(project['engineeringStudio'] as Map<String, dynamic>? ?? {}),
      'recognitionWorkspace': true,
      'recognitionTree': projection['tree'],
      'propertyInspector': true,
    };
    project['interactiveReverse'] = {
      ...(project['interactiveReverse'] as Map<String, dynamic>? ?? {}),
      'recognition': projection,
      'selectionAvailable': true,
    };
    project['liveValidation'] = {
      'recognitionHealth': report.classifications
          .map((e) => e.region.health.name)
          .toList(),
      'automaticExecution': false,
    };
    dashboard['recognition'] = projection;
    dashboard['recognitionStarted'] = true;
    dashboard['recognitionCompleted'] = true;
    session['recognition'] = projection;
    session['workflowStage'] = 'recognition';
    session['history'] = [
      ...(session['history'] as List? ?? const []),
      {'operation': 'Surface Recognition', 'result': report.id},
    ];
  }
}
