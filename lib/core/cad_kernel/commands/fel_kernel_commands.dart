import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../manager/kernel_manager.dart';
import '../api/geometry_kernel_api.dart';
import '../io/kernel_io_models.dart';
import '../models/kernel_models.dart';
import '../opencascade/open_cascade_kernel_plugin.dart';
import '../transactions/kernel_transaction_manager.dart';

class KernelFELState {
  KernelFELState(this.manager);
  final KernelManager manager;
  KernelTransactionManager? transactions;
  dynamic current;
}

class KernelFELCommand implements FELCommand {
  KernelFELCommand(this.name, this.action, this.state);
  @override
  final String name;
  final String action;
  final KernelFELState state;
  @override
  List<FELType> get argumentTypes => switch (action) {
    'load' || 'unload' => const [FELType.string],
    'import' || 'export' => const [FELType.string],
    _ => const [],
  };
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object value;
    switch (action) {
      case 'load':
        value = await state.manager.select(args.first.value as String);
      case 'unload':
        await state.manager.unload(args.first.value as String);
        value = true;
      case 'show':
        value = state.manager.active.descriptor;
      case 'capabilities':
        value = state.manager.active.descriptor.capabilities.values
            .map((e) => e.name)
            .toList();
      case 'topology' || 'graph':
        value = 'Geometry graph is empty: no geometry has been created';
      case 'validate':
        final handle = state.current;
        if (handle is! ShapeHandle) throw StateError('No ShapeHandle selected');
        value = await _interchange.diagnose(handle);
      case 'heal':
        final handle = state.current;
        if (handle is! ShapeHandle) throw StateError('No ShapeHandle selected');
        value = await _interchange.proposeHealing(handle);
      case 'import':
        final format = KernelExchangeFormat.values.byName(
          name.split(' ').last.toLowerCase(),
        );
        value = state.current = await _interchange.importFile(
          args.first.value as String,
          format,
          projectId: context.projectId,
        );
      case 'export':
        final handle = state.current;
        if (handle is! ShapeHandle) throw StateError('No ShapeHandle selected');
        final format = KernelExchangeFormat.values.byName(
          name.split(' ').last.toLowerCase(),
        );
        await _interchange.exportFile(
          handle,
          args.first.value as String,
          format,
        );
        value = true;
      case 'begin':
        state.transactions = KernelTransactionManager(state.manager.active);
        value = state.current = await state.transactions!.begin(
          context.projectId,
        );
      case 'commit':
        final current = state.current;
        if (current == null) throw StateError('BEGIN TRANSACTION required');
        value = state.current = await state.transactions!.commit(current.id);
      case 'rollback':
        final current = state.current;
        if (current == null) throw StateError('BEGIN TRANSACTION required');
        value = state.current = await state.transactions!.rollback(current.id);
      default:
        throw UnsupportedError(action);
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: '$name completed',
    );
  }

  InterchangeGeometryKernelAPI get _interchange {
    final kernel = state.manager.active;
    if (kernel is! InterchangeGeometryKernelAPI) {
      throw StateError('Active kernel does not support import/export');
    }
    return kernel;
  }
}

List<FELCommand> createKernelFELCommands({KernelManager? manager}) {
  final resolved = manager ?? KernelManager();
  if (manager == null) OpenCascadeKernelPlugin().register(resolved);
  final state = KernelFELState(resolved);
  return [
    KernelFELCommand('LOAD KERNEL', 'load', state),
    KernelFELCommand('UNLOAD KERNEL', 'unload', state),
    KernelFELCommand('SHOW KERNEL', 'show', state),
    KernelFELCommand('SHOW CAPABILITIES', 'capabilities', state),
    KernelFELCommand('SHOW TOPOLOGY', 'topology', state),
    KernelFELCommand('SHOW GEOMETRY GRAPH', 'graph', state),
    KernelFELCommand('VALIDATE GEOMETRY', 'validate', state),
    KernelFELCommand('HEAL GEOMETRY', 'heal', state),
    KernelFELCommand('IMPORT STEP', 'import', state),
    KernelFELCommand('IMPORT IGES', 'import', state),
    KernelFELCommand('EXPORT STEP', 'export', state),
    KernelFELCommand('EXPORT IGES', 'export', state),
    KernelFELCommand('BEGIN TRANSACTION', 'begin', state),
    KernelFELCommand('COMMIT TRANSACTION', 'commit', state),
    KernelFELCommand('ROLLBACK TRANSACTION', 'rollback', state),
  ];
}
