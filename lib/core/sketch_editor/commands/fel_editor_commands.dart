import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../sketch_engine/models/sketch_models.dart';
import '../api/sketch_editor_api.dart';
import '../models/editor_models.dart';
import '../snapping/editor_snapping.dart';

class SketchEditorFelCommand implements FELCommand {
  const SketchEditorFelCommand(this.name, this.api);
  @override
  final String name;
  final SketchEditorApi api;
  @override
  List<FELType> get argumentTypes => const [];
  String _text(List<FELValue> a, int i, [String fallback = '']) =>
      a.length > i ? a[i].value.toString() : fallback;
  double _number(List<FELValue> a, int i, [double fallback = 0]) =>
      a.length > i ? (a[i].value as num).toDouble() : fallback;
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> a,
  ) async {
    Object? result;
    switch (name) {
      case 'OPEN SKETCH':
        api.engine.sketch.openSketch(_text(a, 0));
      case 'CLOSE SKETCH':
        api.engine.sketch.closeSketch();
      case 'ACTIVATE TOOL':
        api.engine.toolbar.activate(SketchToolType.values.byName(_text(a, 0)));
      case 'SHOW DOF':
        result = api.dof;
      case 'SHOW QUALITY':
        result = api.quality;
      case 'SHOW ADVISOR':
      case 'SHOW SUGGESTIONS':
        result = api.recommendations;
      case 'SHOW SNAP':
        result = api.engine.snapping.preview;
      case 'ENABLE SNAP':
        api.engine.snapping.settings.enabled.add(
          EditorSnapType.values.byName(_text(a, 0)),
        );
      case 'DISABLE SNAP':
        api.engine.snapping.settings.enabled.remove(
          EditorSnapType.values.byName(_text(a, 0)),
        );
      default:
        final tool =
            _tool[name] ??
            (throw StateError('Unsupported editor command: $name'));
        final id = _text(a, 0);
        if (_creation.contains(tool)) {
          final points = <SketchVector>[
            SketchVector(_number(a, 0), _number(a, 1)),
            SketchVector(_number(a, 2, 1), _number(a, 3, 1)),
          ];
          final preview = api.preview(tool, points);
          result = api.confirm(preview.id);
        } else {
          api.preview(tool, const []);
          api.edit(
            tool,
            [id],
            delta: SketchVector(_number(a, 1), _number(a, 2)),
            value: _number(a, 1, 1),
          );
        }
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }

  static const _creation = {
    SketchToolType.line,
    SketchToolType.rectangle,
    SketchToolType.circle,
    SketchToolType.arc,
    SketchToolType.spline,
    SketchToolType.slot,
    SketchToolType.polygon,
  };
  static const _tool = <String, SketchToolType>{
    'CREATE LINE': SketchToolType.line,
    'CREATE RECTANGLE': SketchToolType.rectangle,
    'CREATE CIRCLE': SketchToolType.circle,
    'CREATE ARC': SketchToolType.arc,
    'CREATE SPLINE': SketchToolType.spline,
    'CREATE SLOT': SketchToolType.slot,
    'CREATE POLYGON': SketchToolType.polygon,
    'MOVE': SketchToolType.move,
    'ROTATE': SketchToolType.rotate,
    'SCALE': SketchToolType.scale,
    'MIRROR': SketchToolType.mirror,
    'OFFSET': SketchToolType.offset,
    'TRIM': SketchToolType.trim,
    'EXTEND': SketchToolType.extend,
    'BREAK': SketchToolType.breakEntity,
    'JOIN': SketchToolType.join,
    'COPY': SketchToolType.copy,
    'DELETE': SketchToolType.delete,
    'LOCK': SketchToolType.lock,
    'UNLOCK': SketchToolType.unlock,
  };
}

List<FELCommand> createSketchEditorFelCommands(SketchEditorApi api) => [
  for (final name in const [
    'OPEN SKETCH',
    'CLOSE SKETCH',
    'ACTIVATE TOOL',
    'CREATE LINE',
    'CREATE RECTANGLE',
    'CREATE CIRCLE',
    'CREATE ARC',
    'CREATE SPLINE',
    'CREATE SLOT',
    'CREATE POLYGON',
    'MOVE',
    'ROTATE',
    'SCALE',
    'MIRROR',
    'OFFSET',
    'TRIM',
    'EXTEND',
    'BREAK',
    'JOIN',
    'COPY',
    'DELETE',
    'LOCK',
    'UNLOCK',
    'SHOW DOF',
    'SHOW QUALITY',
    'SHOW ADVISOR',
    'SHOW SUGGESTIONS',
    'SHOW SNAP',
    'ENABLE SNAP',
    'DISABLE SNAP',
  ])
    SketchEditorFelCommand(name, api),
];
