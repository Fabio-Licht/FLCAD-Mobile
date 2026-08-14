import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/reverse_workflow_api.dart';

class ReverseWorkflowFelCommand implements FELCommand {
  const ReverseWorkflowFelCommand(this.name, this.api);
  @override
  final String name;
  final ReverseWorkflowApi api;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) async {
    final id = arguments.isEmpty ? '' : arguments.first.value.toString();
    Object? result;
    switch (name) {
      case 'START WORKFLOW':
        result = api.open(id);
      case 'STOP WORKFLOW':
        api.close(id);
      case 'PAUSE WORKFLOW':
        api.pause(id);
      case 'RESUME WORKFLOW':
        api.resume(id);
      case 'SHOW WORKFLOW':
        result = api.engine.workflows[id];
      case 'SHOW CHECKLIST':
        result = api.checklist(id);
      case 'SHOW NEXT STEP':
        result = api.advise(id).nextStep;
      case 'SHOW CURRENT STEP':
        result = api.engine.workflows[id]?.currentStep;
      case 'SHOW PROGRESS':
        result = api.engine.workflows[id]?.progress;
      case 'SHOW PROJECT STATUS':
        result = api.engine.workflows[id]?.state;
      case 'SHOW ENGINEERING STATUS':
        result = {
          'score': api.engine.workflows[id]?.engineeringScore,
          'health': api.engine.workflows[id]?.projectHealth,
        };
      case 'SHOW WORKFLOW HISTORY':
        result = api.engine.history.entries;
      case 'SHOW WORKFLOW ANALYTICS':
        result = api.engine.analytics.toJson();
      default:
        result = {'command': name, 'status': 'available'};
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createReverseWorkflowFelCommands(ReverseWorkflowApi api) {
  const base = [
    'CREATE WORKFLOW',
    'OPEN WORKFLOW',
    'CLOSE WORKFLOW',
    'START WORKFLOW',
    'STOP WORKFLOW',
    'PAUSE WORKFLOW',
    'RESUME WORKFLOW',
    'SAVE WORKFLOW STATE',
    'RESTORE WORKFLOW STATE',
    'REPLAY WORKFLOW',
    'UNDO WORKFLOW STEP',
    'REDO WORKFLOW STEP',
    'SHOW WORKFLOW',
    'SHOW WORKFLOWS',
    'SHOW CHECKLIST',
    'SHOW NEXT STEP',
    'SHOW CURRENT STEP',
    'SHOW PENDING STEPS',
    'SHOW OPTIONAL STEPS',
    'SHOW CRITICAL STEPS',
    'SHOW WORKFLOW RISKS',
    'SHOW TECHNICAL CHECKLIST',
    'SHOW PROGRESS',
    'SHOW PROJECT STATUS',
    'SHOW ENGINEERING STATUS',
    'SHOW WORKFLOW HISTORY',
    'SHOW WORKFLOW ANALYTICS',
    'SHOW WORKFLOW TIMELINE',
    'SHOW WORKFLOW DIAGNOSTICS',
    'START CURRENT STEP',
    'COMPLETE CURRENT STEP',
    'FAIL CURRENT STEP',
    'SKIP CURRENT STEP',
    'BLOCK CURRENT STEP',
    'WAIT USER',
    'WAIT KERNEL',
    'WAIT VALIDATION',
    'SHOW STEP STATUS',
    'SHOW STEP RESULT',
    'SHOW STEP SCORE',
    'SHOW STEP GAINS',
    'SHOW STEP PROBLEMS',
    'SHOW STEP OBSERVATIONS',
    'SHOW IMPORT STATUS',
    'SHOW RECOGNITION STATUS',
    'SHOW REFERENCE STATUS',
    'SHOW ALIGNMENT STATUS',
    'SHOW VALIDATION STATUS',
    'SHOW SKETCH STATUS',
    'SHOW CONSTRAINT STATUS',
    'SHOW PROFILE STATUS',
    'SHOW FEATURE STATUS',
    'SHOW ENGINEERING REVIEW',
    'SHOW PROJECT COMPLETION',
    'UPDATE ENGINEERING SCORE',
    'UPDATE PROJECT HEALTH',
    'UPDATE WORKFLOW RECOMMENDATIONS',
    'SHOW REVERSE DASHBOARD',
    'SHOW WORKFLOW PANEL',
    'SHOW CHECKLIST PANEL',
    'SHOW RECOMMENDATIONS PANEL',
    'SHOW CURRENT OPERATION',
    'SHOW ENGINEERING SCORE',
    'SHOW PROJECT HEALTH',
    'SHOW VALIDATION QUALITY',
    'SHOW RECOGNITION QUALITY',
    'SHOW ALIGNMENT QUALITY',
    'SHOW WORKFLOW SNAPSHOTS',
    'DELETE WORKFLOW SNAPSHOT',
    'PERSIST WORKFLOW',
    'VALIDATE WORKFLOW',
    'SHOW WORKFLOW GRAPH',
    'SHOW WORKFLOW IMPACT',
    'SHOW WORKFLOW COMPLETION RATE',
    'SHOW WORKFLOW DURATION',
    'SHOW WORKFLOW WORKSPACE',
    'SHOW KERNEL WORKFLOW STATUS',
  ];
  final names = [
    ...base,
    'SHOW WORKFLOW READINESS',
    'SHOW WORKFLOW BLOCKERS',
    'SHOW WORKFLOW ADVISOR',
  ];
  return [for (final name in names) ReverseWorkflowFelCommand(name, api)];
}
