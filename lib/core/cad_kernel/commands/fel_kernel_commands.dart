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
    'createPlane' || 'createCylinder' => List.filled(8, FELType.number),
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
      case 'version':
        value = state.manager.active.descriptor.version;
      case 'status':
        final kernel = state.manager.active;
        final health = await kernel.healthCheck();
        value = {
          'kernel': kernel.descriptor.name,
          'kernelId': kernel.descriptor.id,
          'version': kernel.descriptor.version,
          'status': health.status.name,
          'message': health.message,
          'loaded': kernel.descriptor.id != 'none',
          'backend': kernel.descriptor.vendor,
          'capabilities': kernel.descriptor.capabilities.values
              .map((e) => e.name)
              .toList(),
        };
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
      case 'createPlane' || 'createCylinder':
        final kernel = state.manager.active;
        final numbers = args.map((e) => (e.value as num).toDouble()).toList();
        final id =
            '${context.projectId}-$action-${DateTime.now().microsecondsSinceEpoch}';
        final transaction = KernelTransaction(
          'fel-${DateTime.now().microsecondsSinceEpoch}',
          context.projectId,
          kernel.descriptor.id,
          DateTime.now(),
          TransactionStatus.active,
          const [],
        );
        final parameters = action == 'createPlane'
            ? <String, dynamic>{
                'origin': numbers.sublist(0, 3),
                'normal': numbers.sublist(3, 6),
                'lowerBound': numbers[6],
                'upperBound': numbers[7],
              }
            : <String, dynamic>{
                'axisOrigin': numbers.sublist(0, 3),
                'axisDirection': numbers.sublist(3, 6),
                'radius': numbers[6],
                'lowerBound': 0.0,
                'upperBound': numbers[7],
              };
        value = state.current = await kernel.create(
          action == 'createPlane' ? 'GENERATE PLANE' : 'GENERATE CYLINDER',
          parameters,
          persistentId: id,
          expectedType: CADShapeType.face,
          transaction: transaction,
        );
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
    KernelFELCommand('SHOW KERNEL VERSION', 'version', state),
    KernelFELCommand('SHOW KERNEL STATUS', 'status', state),
    KernelFELCommand('SHOW CAPABILITIES', 'capabilities', state),
    KernelFELCommand('SHOW TOPOLOGY', 'topology', state),
    KernelFELCommand('SHOW GEOMETRY GRAPH', 'graph', state),
    KernelFELCommand('VALIDATE GEOMETRY', 'validate', state),
    KernelFELCommand('HEAL GEOMETRY', 'heal', state),
    KernelFELCommand('VALIDATE SHAPE', 'validate', state),
    KernelFELCommand('HEAL SHAPE', 'heal', state),
    KernelFELCommand('CREATE PLANE', 'createPlane', state),
    KernelFELCommand('CREATE CYLINDER', 'createCylinder', state),
    KernelFELCommand('IMPORT STEP', 'import', state),
    KernelFELCommand('IMPORT IGES', 'import', state),
    KernelFELCommand('EXPORT STEP', 'export', state),
    KernelFELCommand('EXPORT IGES', 'export', state),
    KernelFELCommand('BEGIN TRANSACTION', 'begin', state),
    KernelFELCommand('COMMIT TRANSACTION', 'commit', state),
    KernelFELCommand('ROLLBACK TRANSACTION', 'rollback', state),
  ];
}
