import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../brain/reverse_brain.dart';

class ReverseIntelligenceCommand implements FELCommand {
  const ReverseIntelligenceCommand(this.name, this.action);
  @override
  final String name;
  final String action;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) async {
    ReverseBrainResult result;
    if (action == 'analyze') {
      final mesh = context.activeMesh;
      if (mesh == null) throw StateError('An active mesh is required');
      result = const ReverseBrain().reason(context.projectId, mesh);
      context.variables['AREI_LAST'] = FELValue(FELType.dynamicType, result);
    } else {
      final stored = context.variables['AREI_LAST']?.value;
      if (stored is! ReverseBrainResult) {
        throw StateError('ANALYZE MESH must be executed first');
      }
      result = stored;
    }
    final Object value;
    final FELType type;
    switch (action) {
      case 'analyze':
        value = result.twin.observation;
        type = FELType.dynamicType;
      case 'classify':
        value = result.twin.classifications;
        type = FELType.dynamicType;
      case 'manufacturing':
        value = result.twin.manufacturing;
        type = FELType.dynamicType;
      case 'plan':
        value = result.twin.plan;
        type = FELType.dynamicType;
      case 'hypotheses':
        value = result.twin.hypotheses;
        type = FELType.dynamicType;
      case 'strategies':
        value = result.twin.decision.candidates;
        type = FELType.dynamicType;
      case 'select':
        value = result.twin.decision;
        type = FELType.dynamicType;
      case 'explain':
        value = result.explanation;
        type = FELType.string;
      case 'validate':
        value = result.twin.validation;
        type = FELType.dynamicType;
      default:
        throw UnsupportedError(action);
    }
    return FELCommandResult(
      value: FELValue(type, value),
      description:
          '$name completed with evidence-based confidence ${result.twin.decision.confidence.toStringAsFixed(3)}',
    );
  }
}

class LearnCorrectionCommand implements FELCommand {
  @override
  String get name => 'LEARN CORRECTION';
  @override
  List<FELType> get argumentTypes => const [FELType.string];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) => throw UnsupportedError(
    'LEARN CORRECTION requires an installed persistent EngineeringMemory adapter',
  );
}

List<FELCommand> createReverseIntelligenceFELCommands() => [
  const ReverseIntelligenceCommand('ANALYZE MESH', 'analyze'),
  const ReverseIntelligenceCommand('CLASSIFY PART', 'classify'),
  const ReverseIntelligenceCommand('ESTIMATE MANUFACTURING', 'manufacturing'),
  const ReverseIntelligenceCommand('PLAN RECONSTRUCTION', 'plan'),
  const ReverseIntelligenceCommand('GENERATE HYPOTHESES', 'hypotheses'),
  const ReverseIntelligenceCommand('RUN STRATEGIES', 'strategies'),
  const ReverseIntelligenceCommand('SELECT STRATEGY', 'select'),
  const ReverseIntelligenceCommand('EXPLAIN DECISION', 'explain'),
  const ReverseIntelligenceCommand('VALIDATE RECONSTRUCTION', 'validate'),
  LearnCorrectionCommand(),
];
