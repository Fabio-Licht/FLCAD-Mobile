import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../sketch_engine/models/sketch_models.dart';
import '../api/revolve_api.dart';
import '../models/revolve_models.dart';

class RevolveFelCommand implements FELCommand {
  const RevolveFelCommand(this.name, this.api);
  @override
  final String name;
  final RevolveApi api;
  @override
  List<FELType> get argumentTypes => const [];
  String _text(List<FELValue> a, int i) =>
      a.length > i ? a[i].value.toString() : '';
  double _number(List<FELValue> a, int i, [double f = 360]) =>
      a.length > i ? (a[i].value as num).toDouble() : f;
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> a,
  ) async {
    Object? result;
    switch (name) {
      case 'CREATE REVOLVE':
        result = api.builder.build(
          input: RevolveInput(
            sketchId: context.projectId,
            profileIds: [_text(a, 0)],
            axis: RevolveAxis(
              origin: const SketchVector(0, 0),
              direction: const SketchVector(0, 1),
            ),
          ),
          parameters: RevolveParameters(angle: _number(a, 1)),
        );
      case 'EDIT REVOLVE':
        api.engine.updateParameters(
          _text(a, 0),
          (p) => p.angle = _number(a, 1),
        );
      case 'DELETE REVOLVE':
        api.rollback(_text(a, 0));
      case 'PREVIEW REVOLVE':
        result = api.preview(_text(a, 0));
      case 'VALIDATE REVOLVE':
        result = api.validate(_text(a, 0));
      case 'SHOW REVOLVE':
        result = api.engine.revolves[_text(a, 0)];
      case 'SHOW REVOLVE PARAMETERS':
        result = api.engine.revolves[_text(a, 0)]?.parameters;
      case 'SHOW REVOLVE QUALITY':
        result = api.quality(_text(a, 0));
      case 'SHOW REVOLVE WARNINGS':
        result = api.engine.revolves[_text(a, 0)]?.diagnostics;
      case 'SHOW REVOLVE HISTORY':
        result = api.engine.history.entries;
      case 'SHOW REVOLVE DEPENDENCIES':
        result = api.engine.graph.dependencies;
      case 'SHOW REVOLVE ANALYTICS':
        result = api.engine.analytics.toJson();
      case 'ROLLBACK REVOLVE':
        api.rollback(_text(a, 0));
      case 'REBUILD REVOLVE':
        result = await api.rebuild(_text(a, 0));
      case 'SUPPRESS REVOLVE':
        api.engine.suppress(_text(a, 0), true);
      case 'UNSUPPRESS REVOLVE':
        api.engine.suppress(_text(a, 0), false);
      case 'LIST REVOLVES':
        result = api.revolves;
      default:
        result = {'command': name, 'status': 'available'};
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createRevolveFelCommands(RevolveApi api) => [
  for (final n in const [
    'CREATE REVOLVE',
    'EDIT REVOLVE',
    'DELETE REVOLVE',
    'PREVIEW REVOLVE',
    'VALIDATE REVOLVE',
    'SHOW REVOLVE',
    'SHOW REVOLVE PARAMETERS',
    'SHOW REVOLVE QUALITY',
    'SHOW REVOLVE WARNINGS',
    'SHOW REVOLVE HISTORY',
    'SHOW REVOLVE DEPENDENCIES',
    'SHOW REVOLVE ANALYTICS',
    'ROLLBACK REVOLVE',
    'REBUILD REVOLVE',
    'SUPPRESS REVOLVE',
    'UNSUPPRESS REVOLVE',
    'LIST REVOLVES',
    'CONFIRM REVOLVE',
    'SHOW REVOLVE PREVIEW',
    'SHOW REVOLVE AXIS',
    'FLIP REVOLVE AXIS',
    'SET REVOLVE AXIS',
    'SET REVOLVE ANGLE',
    'SET REVOLVE TYPE',
    'SET REVOLVE MERGE',
    'SET REVOLVE TARGET',
    'SHOW AXIS DIAGNOSTICS',
    'VALIDATE REVOLVE AXIS',
    'SHOW REVOLVE READINESS',
    'SHOW REVOLVE IMPACT',
    'SHOW REVOLVE UPSTREAM',
    'SHOW REVOLVE DOWNSTREAM',
    'MARK REVOLVE DIRTY',
    'REBUILD REVOLVE PARTIAL',
    'SHOW REVOLVE FAILURES',
    'SHOW REVOLVE SUCCESS RATE',
    'SHOW REVOLVE ADVISOR',
    'SHOW REVOLVE MANUFACTURABILITY',
    'SHOW REVOLVE TIMELINE',
    'SHOW KERNEL REVOLVE CAPABILITY',
  ])
    RevolveFelCommand(n, api),
];
