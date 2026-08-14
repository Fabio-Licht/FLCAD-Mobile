import '../models/surface_extend_models.dart';

abstract interface class SurfaceExtendIntegration {
  void onExtendUpdated(ExtendSession value, Map<String, dynamic> analytics);
}

class OfficialSurfaceExtendIntegration implements SurfaceExtendIntegration {
  OfficialSurfaceExtendIntegration({
    required this.project,
    required this.workflow,
    required this.session,
    required this.studio,
    required this.intelligence,
  });
  final Map<String, dynamic> project, workflow, session, studio, intelligence;
  @override
  void onExtendUpdated(ExtendSession value, Map<String, dynamic> analytics) {
    project['surfaceExtend'] = value.toJson();
    workflow['surfaceExtendStatus'] = value.status.name;
    session['surfaceExtend'] = value.toJson();
    studio['professionalExtendWorkspace'] = true;
    intelligence['extendAdvisor'] = {
      'automaticActions': false,
      'analysis': value.analysis?.toJson(),
    };
    project['extendAnalytics'] = analytics;
  }
}
