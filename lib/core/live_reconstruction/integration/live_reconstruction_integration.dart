import '../models/live_reconstruction_models.dart';

abstract interface class LiveReconstructionIntegration {
  void onReconstructionUpdated(LiveReconstruction value);
}

class OfficialLiveReconstructionIntegration
    implements LiveReconstructionIntegration {
  OfficialLiveReconstructionIntegration({
    required this.project,
    required this.workflow,
    required this.session,
    required this.studio,
    required this.intelligence,
    required this.liveValidation,
  });
  final Map<String, dynamic> project,
      workflow,
      session,
      studio,
      intelligence,
      liveValidation;
  @override
  void onReconstructionUpdated(LiveReconstruction value) {
    final projection = value.toJson();
    project['liveReconstruction'] = projection;
    workflow['liveReconstructionState'] = value.state.name;
    session['liveReconstruction'] = projection;
    session['timeline'] = value.timeline;
    studio['liveReconstructionWorkspace'] = true;
    studio['affectedObjects'] = value.preview?.affected.toJson();
    intelligence['reconstructionAdvisor'] = value.advice
        .map((e) => e.toJson())
        .toList();
    intelligence['automaticActions'] = false;
    liveValidation['dirtyObjects'] =
        value.preview?.affected.validation.toList() ?? const [];
  }
}
