import '../../cad_kernel/models/kernel_models.dart';
import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/feature_api.dart';
import '../models/feature_models.dart';

class FeatureFELState {
  FeatureFELState(this.api);
  final FeatureApi? api;
  final Map<String, ShapeHandle> shapes = {};
  FeatureResult? current;
}

class FeatureFELCommand implements FELCommand {
  const FeatureFELCommand(
    this.name,
    this.action,
    this.state,
    this.argumentTypes,
  );
  @override
  final String name;
  final String action;
  final FeatureFELState state;
  @override
  final List<FELType> argumentTypes;
  FeatureApi get _api =>
      state.api ??
      (throw StateError(
        'CAD Features are not configured for the active project',
      ));
  ShapeHandle _shape(Object? id) =>
      state.shapes[id] ?? (throw StateError('Shape $id not found'));
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    switch (action) {
      case 'extrude':
        value = await _api.extrude(
          _shape(args[0].value),
          distance: (args[1].value as num).toDouble(),
        );
      case 'revolve':
        value = await _api.revolve(
          _shape(args[0].value),
          _shape(args[1].value),
          angle: (args[2].value as num).toDouble(),
        );
      case 'sweep':
        value = await _api.sweep(_shape(args[0].value), _shape(args[1].value));
      case 'loft':
        value = await _api.loft(args.map((e) => _shape(e.value)).toList());
      case 'union':
        value = await _api.union(args.map((e) => _shape(e.value)).toList());
      case 'subtract':
        value = await _api.subtract(
          _shape(args[0].value),
          _shape(args[1].value),
        );
      case 'intersect':
        value = await _api.intersect(args.map((e) => _shape(e.value)).toList());
      case 'rebuild':
        final current = state.current;
        if (current?.feature.output == null) {
          throw StateError('No feature output selected');
        }
        value = await _api.engine.rebuild(
          current!.feature.output!.persistentId,
          current.feature.output!,
        );
      case 'heal':
        value = await _api.engine.healing(_shape(args[0].value));
      case 'validate':
        value = await _api.engine.validateSolid(_shape(args[0].value));
      default:
        throw UnsupportedError(action);
    }
    if (value is FeatureResult) {
      state.current = value;
      final output = value.feature.output;
      if (output != null) state.shapes[output.persistentId] = output;
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: '$name completed',
    );
  }
}

List<FELCommand> createFeatureFELCommands({FeatureApi? api}) {
  final state = FeatureFELState(api);
  return [
    FeatureFELCommand('EXTRUDE', 'extrude', state, const [
      FELType.string,
      FELType.number,
    ]),
    FeatureFELCommand('REVOLVE', 'revolve', state, const [
      FELType.string,
      FELType.string,
      FELType.number,
    ]),
    FeatureFELCommand('SWEEP', 'sweep', state, const [
      FELType.string,
      FELType.string,
    ]),
    FeatureFELCommand('LOFT', 'loft', state, const [FELType.string]),
    FeatureFELCommand('BOOLEAN UNION', 'union', state, const [FELType.string]),
    FeatureFELCommand('BOOLEAN SUBTRACT', 'subtract', state, const [
      FELType.string,
      FELType.string,
    ]),
    FeatureFELCommand('BOOLEAN INTERSECT', 'intersect', state, const [
      FELType.string,
    ]),
    FeatureFELCommand('REBUILD FEATURES', 'rebuild', state, const []),
    FeatureFELCommand('HEAL SHAPE', 'heal', state, const [FELType.string]),
    FeatureFELCommand('VALIDATE SOLID', 'validate', state, const [
      FELType.string,
    ]),
  ];
}
