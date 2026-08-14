import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/transition_api.dart';

class TransitionFelCommand implements FELCommand {
  const TransitionFelCommand(this.name, this.api);
  @override
  final String name;
  final TransitionApi api;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) async {
    final id = arguments.isEmpty ? '' : arguments.first.value.toString();
    Object? value;
    switch (name) {
      case 'PREVIEW SWEEP':
      case 'PREVIEW LOFT':
        value = api.preview(id);
      case 'VALIDATE SWEEP':
      case 'VALIDATE LOFT':
        value = api.validate(id);
      case 'SHOW TRANSITION QUALITY':
        value = api.quality(id);
      case 'SHOW TRANSITION HISTORY':
        value = api.engine.history.entries;
      case 'SHOW TRANSITION ANALYTICS':
        value = api.engine.analytics.toJson();
      case 'ROLLBACK SWEEP':
      case 'ROLLBACK LOFT':
        api.rollback(id);
      case 'LIST SWEEPS':
        value = api.features.where((e) => e.family.name == 'sweep').toList();
      case 'LIST LOFTS':
        value = api.features.where((e) => e.family.name == 'loft').toList();
      default:
        value = {'command': name, 'status': 'available'};
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: name,
    );
  }
}

List<FELCommand> createTransitionFelCommands(TransitionApi api) => [
  for (final name in const [
    'CREATE SWEEP',
    'CREATE LOFT',
    'EDIT SWEEP',
    'EDIT LOFT',
    'DELETE SWEEP',
    'DELETE LOFT',
    'PREVIEW SWEEP',
    'PREVIEW LOFT',
    'VALIDATE SWEEP',
    'VALIDATE LOFT',
    'SHOW SWEEP',
    'SHOW LOFT',
    'SHOW TRANSITION QUALITY',
    'SHOW TRANSITION HISTORY',
    'SHOW TRANSITION PARAMETERS',
    'SHOW TRANSITION ANALYTICS',
    'ROLLBACK SWEEP',
    'ROLLBACK LOFT',
    'SUPPRESS SWEEP',
    'SUPPRESS LOFT',
    'UNSUPPRESS SWEEP',
    'UNSUPPRESS LOFT',
    'LIST SWEEPS',
    'LIST LOFTS',
    'CONFIRM SWEEP',
    'CONFIRM LOFT',
    'REBUILD SWEEP',
    'REBUILD LOFT',
    'SHOW TRANSITION PREVIEW',
    'SHOW TRANSITION WARNINGS',
    'SHOW TRANSITION READINESS',
    'SHOW TRANSITION DEPENDENCIES',
    'SHOW TRANSITION UPSTREAM',
    'SHOW TRANSITION DOWNSTREAM',
    'SHOW TRANSITION IMPACT',
    'MARK TRANSITION DIRTY',
    'REBUILD TRANSITION PARTIAL',
    'SHOW TRANSITION FAILURES',
    'SHOW TRANSITION SUCCESS RATE',
    'SHOW TRANSITION ADVISOR',
    'SHOW TRANSITION MANUFACTURABILITY',
    'SHOW TRANSITION COMPLEXITY',
    'SHOW SWEEP PATH',
    'SHOW SWEEP GUIDES',
    'SHOW LOFT SECTIONS',
    'SHOW LOFT GUIDES',
    'SET SWEEP PATH',
    'SET SWEEP GUIDES',
    'SET LOFT SECTIONS',
    'SET LOFT GUIDES',
    'SET TRANSITION MERGE',
    'SET TRANSITION THICKNESS',
    'SET TRANSITION STRATEGY',
    'SHOW TRANSITION TIMELINE',
    'SHOW KERNEL SWEEP CAPABILITY',
    'SHOW KERNEL LOFT CAPABILITY',
  ])
    TransitionFelCommand(name, api),
];
