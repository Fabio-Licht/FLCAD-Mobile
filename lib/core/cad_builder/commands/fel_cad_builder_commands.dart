import '../../cad_kernel/models/kernel_models.dart';
import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/cad_builder_api.dart';
import '../models/cad_models.dart';

class CadBuilderFELState {
  CadBuilderFELState(this.api);
  final CadBuilderApi? api;
  final Map<String, ShapeHandle> shapes = {};
  ShapeHandle? current;
}

class CadBuilderFELCommand implements FELCommand {
  const CadBuilderFELCommand(
    this.name,
    this.action,
    this.state,
    this.argumentTypes,
  );
  @override
  final String name;
  final String action;
  final CadBuilderFELState state;
  @override
  final List<FELType> argumentTypes;
  CadBuilderApi get _api =>
      state.api ??
      (throw StateError(
        'CAD Builder is not configured for the active project',
      ));
  ShapeHandle _shape(Object? value) =>
      state.shapes[value] ?? (throw StateError('Shape $value not found'));
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    switch (action) {
      case 'vertex':
        value = await _api.vertex.point(
          (args[0].value as num).toDouble(),
          (args[1].value as num).toDouble(),
          (args[2].value as num).toDouble(),
        );
      case 'edge':
        value = await _api.edge.line(
          _shape(args[0].value),
          _shape(args[1].value),
        );
      case 'wire':
        value = await _api.wire.build(
          args.map((e) => _shape(e.value)).toList(),
          closed: true,
        );
      case 'face':
        value = await _api.face.planar(_shape(args[0].value));
      case 'shell':
        value = await _api.shell.sew(args.map((e) => _shape(e.value)).toList());
      case 'solid':
        value = await _api.solid.fromClosedShell(_shape(args[0].value));
      case 'topology':
        value = _api.engine.graph;
      case 'validate':
        final handle = _shape(args[0].value);
        value = await _api.engine.kernel.validate(handle, const {
          'manifold',
          'closure',
          'orientation',
          'degeneration',
        });
      case 'show':
        value = _shape(args[0].value);
      case 'delete':
        final id = args[0].value as String;
        await _api.engine.delete(id);
        state.shapes.remove(id);
        value = true;
      default:
        throw UnsupportedError(action);
    }
    if (value is CadBuildResult) {
      final handle = value.entity?.handle;
      if (handle != null) {
        state.shapes[handle.persistentId] = handle;
        state.current = handle;
      }
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: '$name completed',
    );
  }
}

List<FELCommand> createCadBuilderFELCommands({CadBuilderApi? api}) {
  final state = CadBuilderFELState(api);
  return [
    CadBuilderFELCommand('CREATE VERTEX', 'vertex', state, const [
      FELType.number,
      FELType.number,
      FELType.number,
    ]),
    CadBuilderFELCommand('CREATE EDGE', 'edge', state, const [
      FELType.string,
      FELType.string,
    ]),
    CadBuilderFELCommand('CREATE WIRE', 'wire', state, const [FELType.string]),
    CadBuilderFELCommand('CREATE FACE', 'face', state, const [FELType.string]),
    CadBuilderFELCommand('CREATE SHELL', 'shell', state, const [
      FELType.string,
    ]),
    CadBuilderFELCommand('CREATE SOLID', 'solid', state, const [
      FELType.string,
    ]),
    CadBuilderFELCommand('SHOW TOPOLOGY', 'topology', state, const []),
    CadBuilderFELCommand('VALIDATE SHAPE', 'validate', state, const [
      FELType.string,
    ]),
    CadBuilderFELCommand('SHOW SHAPE', 'show', state, const [FELType.string]),
    CadBuilderFELCommand('DELETE SHAPE', 'delete', state, const [
      FELType.string,
    ]),
  ];
}
