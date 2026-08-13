import '../../professional_recognition/models/professional_recognition_models.dart';
import '../collaboration/human_collaboration.dart';
import '../models/reconstruction_intelligence_models.dart';
import '../planner/engineering_reconstruction_planner.dart';

class EngineeringReconstructionApi {
  EngineeringReconstructionApi({EngineeringReconstructionPlanner? planner})
    : planner = planner ?? EngineeringReconstructionPlanner();
  final EngineeringReconstructionPlanner planner;
  final collaboration = ERIHumanCollaboration();
  EngineeringReconstructionPlan? _current;
  EngineeringReconstructionPlan get current =>
      _current ?? (throw StateError('ERI plan not built'));
  Future<EngineeringReconstructionPlan> plan(ProfessionalRecognitionReport r) =>
      planner
          .plan(ERIPlanningInput(r, previous: _current))
          .then((v) => _current = v);
  Future<EngineeringReconstructionPlan> replan(
    ProfessionalRecognitionReport r,
    List<String> changed,
  ) => planner
      .plan(ERIPlanningInput(r, previous: _current, changedSourceIds: changed))
      .then((v) => _current = v);
  Future<EngineeringReconstructionPlan> override(
    String id,
    ERINodeStatus status, {
    required String actor,
    required String reason,
    String? title,
  }) => collaboration
      .intervene(
        current,
        id,
        status,
        actor: actor,
        reason: reason,
        replacementTitle: title,
      )
      .then((v) => _current = v);
  String exportPlan() =>
      '{"schema":"flcad.eri-plan","version":1,"projectId":"${current.projectId}","revision":${current.revision},"strategy":"${current.selectedStrategyId}","nodes":${current.nodes.length}}';
}
