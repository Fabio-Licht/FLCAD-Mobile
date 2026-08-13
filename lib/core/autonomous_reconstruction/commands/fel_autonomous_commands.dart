import '../../engineering_cognition/orchestrator/cognition_orchestrator.dart';
import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/autonomous_reconstruction_api.dart';
import '../models/reconstruction_models.dart';
import '../serialization/workflow_serialization.dart';

class AutonomousFELCommand implements FELCommand {
  AutonomousFELCommand(this.name, this.action, this.api);
  @override
  final String name;
  final String action;
  final AutonomousReconstructionApi api;
  @override
  List<FELType> get argumentTypes => ['execute', 'update'].contains(action)
      ? const [FELType.string]
      : const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    ReconstructionWorkflow workflow;
    final stored = context.variables['AUTONOMOUS_WORKFLOW']?.value;
    if (action == 'build' || action == 'plan' || action == 'rebuild') {
      final cognition = context.variables['COGNITION_LAST']?.value;
      if (cognition is! CognitionResult) {
        throw StateError('ANALYZE ENGINEERING must be executed first');
      }
      workflow = stored is ReconstructionWorkflow
          ? api.rebuild(
              cognition.snapshot,
              action == 'rebuild'
                  ? 'Explicit FEL rebuild'
                  : 'Cognition changed',
            )
          : api.build(cognition.snapshot);
      context.variables['AUTONOMOUS_WORKFLOW'] = FELValue(
        FELType.dynamicType,
        workflow,
      );
    } else {
      if (stored is! ReconstructionWorkflow) {
        throw StateError('BUILD RECONSTRUCTION must be executed first');
      }
      workflow = stored;
      switch (action) {
        case 'next':
          final next = api.advisor(workflow.id);
          return FELCommandResult(
            value: FELValue(FELType.dynamicType, next),
            description: next.explanation,
          );
        case 'show':
          return FELCommandResult(
            value: FELValue(
              FELType.string,
              const WorkflowSerialization().encode(workflow),
            ),
            description: 'Workflow serialized',
          );
        case 'explain':
          final text = workflow.stages
              .map((s) => '${s.order}. ${s.name}: ${s.decision.explanation}')
              .join('\n');
          return FELCommandResult(
            value: FELValue(FELType.string, text),
            description: 'Workflow explained',
          );
        case 'update':
          final cognition = context.variables['COGNITION_LAST']?.value;
          if (cognition is! CognitionResult) {
            throw StateError('ANALYZE ENGINEERING must be executed first');
          }
          workflow = api.rebuild(
            cognition.snapshot,
            args.first.value as String,
          );
        case 'execute':
          workflow = api.executeStage(workflow.id, args.first.value as String);
        case 'pause':
          workflow = api.pause(workflow.id);
        case 'resume':
          workflow = api.resume(workflow.id);
        default:
          throw UnsupportedError(action);
      }
      context.variables['AUTONOMOUS_WORKFLOW'] = FELValue(
        FELType.dynamicType,
        workflow,
      );
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, workflow),
      description:
          '$name revision ${workflow.revision}, ${(workflow.progress * 100).toStringAsFixed(1)}% complete',
    );
  }
}

List<FELCommand> createAutonomousFELCommands() {
  final api = AutonomousReconstructionApi();
  return [
    AutonomousFELCommand('BUILD RECONSTRUCTION', 'build', api),
    AutonomousFELCommand('PLAN RECONSTRUCTION', 'plan', api),
    AutonomousFELCommand('NEXT STEP', 'next', api),
    AutonomousFELCommand('SHOW PLAN', 'show', api),
    AutonomousFELCommand('EXPLAIN PLAN', 'explain', api),
    AutonomousFELCommand('UPDATE PLAN', 'update', api),
    AutonomousFELCommand('EXECUTE STAGE', 'execute', api),
    AutonomousFELCommand('PAUSE PLAN', 'pause', api),
    AutonomousFELCommand('RESUME PLAN', 'resume', api),
    AutonomousFELCommand('REBUILD PLAN', 'rebuild', api),
  ];
}
