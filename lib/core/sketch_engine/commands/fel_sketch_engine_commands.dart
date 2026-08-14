import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/sketch_engine_api.dart';
import '../models/sketch_models.dart';

class SketchEngineFelCommand implements FELCommand {
  const SketchEngineFelCommand(
    this.name,
    this.api, [
    this.argumentTypes = const [],
  ]);
  @override
  final String name;
  final SketchEngineApi api;
  @override
  final List<FELType> argumentTypes;
  double _number(List<FELValue> a, int i, [double fallback = 0]) =>
      a.length > i ? (a[i].value as num).toDouble() : fallback;
  String _text(List<FELValue> a, int i, [String fallback = '']) =>
      a.length > i ? a[i].value.toString() : fallback;
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> a,
  ) async {
    Object? result;
    switch (name) {
      case 'CREATE SKETCH':
        result = api.createSketch(_text(a, 0, 'Sketch'));
        break;
      case 'DELETE SKETCH':
        api.deleteSketch(_text(a, 0, api.engine.activeSketchId ?? ''));
        break;
      case 'OPEN SKETCH':
        api.openSketch(_text(a, 0));
        break;
      case 'CLOSE SKETCH':
        api.closeSketch();
        break;
      case 'CREATE POINT':
        result = api.builders.point.build(
          SketchVector(_number(a, 0), _number(a, 1)),
        );
        break;
      case 'CREATE LINE':
        result = api.builders.line.build(
          SketchVector(_number(a, 0), _number(a, 1)),
          SketchVector(_number(a, 2), _number(a, 3)),
        );
        break;
      case 'CREATE CIRCLE':
        result = api.builders.circle.build(
          SketchVector(_number(a, 0), _number(a, 1)),
          _number(a, 2, 1),
        );
        break;
      case 'CREATE ARC':
        result = api.builders.arc.build(
          SketchVector(_number(a, 0), _number(a, 1)),
          _number(a, 2, 1),
          _number(a, 3),
          _number(a, 4),
        );
        break;
      case 'CREATE SPLINE':
        result = api.builders.spline.build([
          SketchVector(_number(a, 0), _number(a, 1)),
          SketchVector(_number(a, 2), _number(a, 3)),
        ]);
        break;
      case 'CREATE ELLIPSE':
        result = api.builders.ellipse.build(
          SketchVector(_number(a, 0), _number(a, 1)),
          _number(a, 2, 1),
          _number(a, 3, 1),
        );
        break;
      case 'MOVE ENTITY':
        api.move(_text(a, 0), SketchVector(_number(a, 1), _number(a, 2)));
        break;
      case 'ROTATE ENTITY':
        api.rotate(_text(a, 0), _number(a, 1));
        break;
      case 'SCALE ENTITY':
        api.scale(_text(a, 0), _number(a, 1, 1));
        break;
      case 'MIRROR ENTITY':
        api.mirror(_text(a, 0));
        break;
      case 'SET CONSTRUCTION':
        api.setConstruction(_text(a, 0), true);
        break;
      case 'SET REFERENCE':
        api.setReference(_text(a, 0), true);
        break;
      case 'LIST SKETCH':
        result = api.sketches;
        break;
      case 'SHOW SKETCH':
        result = api.engine.sketches[_text(a, 0)];
        break;
      case 'SELECT ENTITY':
        final entity = api.entity(_text(a, 0));
        if (entity == null) throw StateError('Unknown entity');
        api.engine.selection.select(entity);
        result = entity;
        break;
      case 'DELETE ENTITY':
        api.deleteEntity(_text(a, 0));
        break;
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createSketchEngineFelCommands(SketchEngineApi api) => [
  for (final name in const [
    'CREATE SKETCH',
    'DELETE SKETCH',
    'OPEN SKETCH',
    'CLOSE SKETCH',
    'CREATE POINT',
    'CREATE LINE',
    'CREATE CIRCLE',
    'CREATE ARC',
    'CREATE SPLINE',
    'CREATE ELLIPSE',
    'MOVE ENTITY',
    'ROTATE ENTITY',
    'SCALE ENTITY',
    'MIRROR ENTITY',
    'SET CONSTRUCTION',
    'SET REFERENCE',
    'LIST SKETCH',
    'SHOW SKETCH',
    'SELECT ENTITY',
    'DELETE ENTITY',
  ])
    SketchEngineFelCommand(name, api),
];
