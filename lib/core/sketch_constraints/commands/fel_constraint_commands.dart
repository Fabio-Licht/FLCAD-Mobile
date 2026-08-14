import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/constraint_api.dart';
import '../models/constraint_models.dart';

class ConstraintFelCommand implements FELCommand {
  const ConstraintFelCommand(this.name, this.api, [this.type]);
  @override
  final String name;
  final ConstraintApi api;
  final SketchConstraintType? type;
  @override
  List<FELType> get argumentTypes => const [];
  String _text(List<FELValue> a, int i, [String fallback = '']) =>
      a.length > i ? a[i].value.toString() : fallback;
  double? _value(List<FELValue> a, int i) =>
      a.length > i ? (a[i].value as num).toDouble() : null;
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? result;
    switch (name) {
      case 'DELETE CONSTRAINT':
        api.delete(_text(args, 0));
        break;
      case 'ENABLE CONSTRAINT':
        api.enable(_text(args, 0));
        break;
      case 'DISABLE CONSTRAINT':
        api.disable(_text(args, 0));
        break;
      case 'SUPPRESS CONSTRAINT':
        api.suppress(_text(args, 0));
        break;
      case 'SOLVE SKETCH':
        result = await api.solve();
        break;
      case 'REBUILD SKETCH':
        result = await api.rebuild();
        break;
      case 'SHOW CONSTRAINTS':
      case 'LIST CONSTRAINTS':
        result = api.constraints;
        break;
      case 'SHOW CONFLICTS':
        result = api.constraints
            .where((c) => c.status == ConstraintStatus.conflicting)
            .toList();
        break;
      case 'SHOW OVERDEFINED':
        result = api.constraints
            .where((c) => c.status == ConstraintStatus.overdefined)
            .toList();
        break;
      case 'SHOW UNDERDEFINED':
        result = api.constraints
            .where((c) => c.status == ConstraintStatus.underdefined)
            .toList();
        break;
      case 'SHOW DIAGNOSTICS':
        result = api.engine.lastResult?.diagnostics ?? const [];
        break;
      default:
        final constraintType =
            type ?? SketchConstraintType.values.byName(_text(args, 0));
        final start = type == null ? 1 : 0;
        final refs = <String>[
          _text(args, start),
          if (args.length > start + 1 && args[start + 1].value is String)
            _text(args, start + 1),
        ]..removeWhere((e) => e.isEmpty);
        result = api.builders
            .of(constraintType)
            .build(refs, value: _value(args, start + refs.length));
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createConstraintFelCommands(ConstraintApi api) => [
  ConstraintFelCommand('CREATE CONSTRAINT', api),
  for (final name in const [
    'DELETE CONSTRAINT',
    'ENABLE CONSTRAINT',
    'DISABLE CONSTRAINT',
    'SUPPRESS CONSTRAINT',
    'SOLVE SKETCH',
    'SHOW CONSTRAINTS',
    'LIST CONSTRAINTS',
    'SHOW CONFLICTS',
    'SHOW OVERDEFINED',
    'SHOW UNDERDEFINED',
    'SHOW DIAGNOSTICS',
  ])
    ConstraintFelCommand(name, api),
  for (final entry in const {
    'CREATE DISTANCE': SketchConstraintType.distance,
    'CREATE ANGLE': SketchConstraintType.angle,
    'CREATE RADIUS': SketchConstraintType.radius,
    'CREATE DIAMETER': SketchConstraintType.diameter,
    'CREATE OFFSET': SketchConstraintType.offset,
    'CREATE PARALLEL': SketchConstraintType.parallel,
    'CREATE PERPENDICULAR': SketchConstraintType.perpendicular,
    'CREATE TANGENT': SketchConstraintType.tangent,
    'CREATE COINCIDENT': SketchConstraintType.coincident,
    'CREATE HORIZONTAL': SketchConstraintType.horizontal,
    'CREATE VERTICAL': SketchConstraintType.vertical,
    'CREATE EQUAL': SketchConstraintType.equal,
  }.entries)
    ConstraintFelCommand(entry.key, api, entry.value),
  ConstraintFelCommand('REBUILD SKETCH', api),
];
