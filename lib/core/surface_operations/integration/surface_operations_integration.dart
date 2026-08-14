import '../models/surface_operation_models.dart';

abstract interface class SurfaceOperationsIntegration {
  void onOperationUpdated(
    SurfaceOperation operation,
    List<SurfaceOperationAdvice> advice,
  );
}

class OfficialSurfaceOperationsIntegration
    implements SurfaceOperationsIntegration {
  OfficialSurfaceOperationsIntegration({
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
  void onOperationUpdated(
    SurfaceOperation operation,
    List<SurfaceOperationAdvice> advice,
  ) {
    final projection = operation.toJson();
    project['surfaceOperation'] = projection;
    workflow['surfaceOperationStatus'] = operation.status.name;
    session['surfaceOperation'] = projection;
    session['history'] = [
      ...(session['history'] as List? ?? const []),
      {'operation': operation.id, 'status': operation.status.name},
    ];
    studio['surfaceOperationsWorkspace'] = true;
    studio['operation'] = projection;
    intelligence['surfaceOperationAdvisor'] = advice
        .map((e) => e.toJson())
        .toList();
    intelligence['automaticActions'] = false;
    liveValidation['surfaceOperationValidation'] = operation.validation
        ?.toJson();
  }
}
