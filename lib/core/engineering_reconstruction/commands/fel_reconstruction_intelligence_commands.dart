import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../professional_recognition/api/professional_recognition_api.dart';
import '../advisor/reconstruction_intelligence_advisor.dart';
import '../api/engineering_reconstruction_api.dart';

class ERIFELCommand implements FELCommand {
  ERIFELCommand(this.name, this.action, this.api, this.recognition);
  @override
  final String name;
  final String action;
  final EngineeringReconstructionApi api;
  final ProfessionalRecognitionApi recognition;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object value;
    switch (action) {
      case 'plan':
        value = await api.plan(recognition.last);
      case 'show':
        value = api.current;
      case 'strategies':
        value = api.current.strategies;
      case 'dependencies':
        value = {for (final n in api.current.nodes) n.id: n.dependencies};
      case 'next':
        value =
            const ReconstructionIntelligenceAdvisor().next(api.current) ??
            'No ready step';
      case 'timeline':
        value = api.current.timeline;
      case 'risk':
        value = {for (final n in api.current.nodes) n.id: n.risk.name};
      case 'replan':
        value = await api.replan(
          recognition.last,
          recognition.last.primitives.map((e) => e.recognition.id).toList(),
        );
      case 'export':
        value = api.exportPlan();
      case 'compare':
        value = api.current.strategies;
      default:
        throw UnsupportedError(action);
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: '$name completed',
    );
  }
}

List<FELCommand> createERIFELCommands({
  EngineeringReconstructionApi? api,
  ProfessionalRecognitionApi? recognition,
}) {
  final a = api ?? EngineeringReconstructionApi(),
      r = recognition ?? ProfessionalRecognitionApi();
  return [
    ERIFELCommand('PLAN RECONSTRUCTION', 'plan', a, r),
    ERIFELCommand('SHOW PLAN', 'show', a, r),
    ERIFELCommand('SHOW STRATEGIES', 'strategies', a, r),
    ERIFELCommand('SHOW DEPENDENCIES', 'dependencies', a, r),
    ERIFELCommand('SHOW NEXT STEP', 'next', a, r),
    ERIFELCommand('SHOW TIMELINE', 'timeline', a, r),
    ERIFELCommand('SHOW RISK', 'risk', a, r),
    ERIFELCommand('REPLAN', 'replan', a, r),
    ERIFELCommand('EXPORT PLAN', 'export', a, r),
    ERIFELCommand('COMPARE STRATEGIES', 'compare', a, r),
  ];
}
