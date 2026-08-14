import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/extrude_api.dart';
import '../models/extrude_models.dart';

class ExtrudeFelCommand implements FELCommand {
  const ExtrudeFelCommand(this.name, this.api);
  @override
  final String name;
  final ExtrudeApi api;
  @override
  List<FELType> get argumentTypes => const [];
  String _text(List<FELValue> a, int i) =>
      a.length > i ? a[i].value.toString() : '';
  double _number(List<FELValue> a, int i, [double f = 1]) =>
      a.length > i ? (a[i].value as num).toDouble() : f;
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> a,
  ) async {
    Object? result;
    switch (name) {
      case 'CREATE EXTRUDE':
        result = api.builder.build(
          input: ExtrudeInput(
            sketchId: context.projectId,
            profileIds: [_text(a, 0)],
          ),
          parameters: ExtrudeParameters(distance: _number(a, 1)),
        );
      case 'EDIT EXTRUDE':
        api.engine.updateParameters(
          _text(a, 0),
          (p) => p.distance = _number(a, 1),
        );
      case 'DELETE EXTRUDE':
        api.engine.rollback(_text(a, 0));
      case 'PREVIEW EXTRUDE':
        result = api.preview(_text(a, 0));
      case 'SHOW EXTRUDE':
        result = api.engine.extrudes[_text(a, 0)];
      case 'SHOW EXTRUDE PARAMETERS':
        result = api.engine.extrudes[_text(a, 0)]?.parameters;
      case 'SHOW EXTRUDE QUALITY':
        result = api.quality(_text(a, 0));
      case 'SHOW EXTRUDE WARNINGS':
        result = api.engine.extrudes[_text(a, 0)]?.diagnostics;
      case 'VALIDATE EXTRUDE':
        result = api.validate(_text(a, 0));
      case 'REBUILD EXTRUDE':
        result = await api.rebuild(_text(a, 0));
      case 'ROLLBACK EXTRUDE':
        api.rollback(_text(a, 0));
      case 'SUPPRESS EXTRUDE':
        api.engine.suppress(_text(a, 0), true);
      case 'UNSUPPRESS EXTRUDE':
        api.engine.suppress(_text(a, 0), false);
      case 'LIST EXTRUDES':
        result = api.extrudes;
      case 'SHOW EXTRUDE HISTORY':
        result = api.engine.history.entries;
      case 'SHOW EXTRUDE DEPENDENCIES':
        result = api.engine.graph.dependencies;
      case 'SHOW EXTRUDE ANALYTICS':
        result = api.engine.analytics.toJson();
      default:
        result = {'command': name, 'status': 'available'};
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createExtrudeFelCommands(ExtrudeApi api) => [
  for (final n in const [
    'CREATE EXTRUDE',
    'EDIT EXTRUDE',
    'DELETE EXTRUDE',
    'PREVIEW EXTRUDE',
    'SHOW EXTRUDE',
    'SHOW EXTRUDE PARAMETERS',
    'SHOW EXTRUDE QUALITY',
    'SHOW EXTRUDE WARNINGS',
    'VALIDATE EXTRUDE',
    'REBUILD EXTRUDE',
    'ROLLBACK EXTRUDE',
    'SUPPRESS EXTRUDE',
    'UNSUPPRESS EXTRUDE',
    'LIST EXTRUDES',
    'SHOW EXTRUDE HISTORY',
    'SHOW EXTRUDE DEPENDENCIES',
    'SHOW EXTRUDE ANALYTICS',
    'CONFIRM EXTRUDE',
    'SHOW EXTRUDE PREVIEW',
    'SHOW KERNEL STATUS',
    'SHOW EXTRUDE READINESS',
    'SHOW EXTRUDE DIRECTION',
    'SHOW EXTRUDE DISTANCE',
    'REVERSE EXTRUDE',
    'SET EXTRUDE DISTANCE',
    'SET EXTRUDE DIRECTION',
    'SET EXTRUDE DRAFT',
    'SET EXTRUDE OFFSET',
    'SET EXTRUDE MERGE',
    'SET EXTRUDE TARGET',
    'SET EXTRUDE TYPE',
    'SHOW EXTRUDE IMPACT',
    'SHOW EXTRUDE UPSTREAM',
    'SHOW EXTRUDE DOWNSTREAM',
    'MARK EXTRUDE DIRTY',
    'REBUILD EXTRUDE PARTIAL',
    'SHOW EXTRUDE FAILURES',
    'SHOW EXTRUDE SUCCESS RATE',
    'SHOW EXTRUDE ADVISOR',
    'SHOW EXTRUDE MANUFACTURABILITY',
  ])
    ExtrudeFelCommand(n, api),
];
