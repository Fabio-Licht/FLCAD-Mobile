import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/feature_modeling_api.dart';
import '../models/feature_models.dart';

class FeatureModelingFelCommand implements FELCommand {
  const FeatureModelingFelCommand(this.name, this.api);
  @override
  final String name;
  final FeatureModelingApi api;
  @override
  List<FELType> get argumentTypes => const [];
  String _text(List<FELValue> a, int i) =>
      a.length > i ? a[i].value.toString() : '';
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> a,
  ) async {
    Object? result;
    switch (name) {
      case 'CREATE FEATURE':
        result = api.builders
            .of(FeatureType.values.byName(_text(a, 0)))
            .build();
      case 'DELETE FEATURE':
        api.delete(_text(a, 0));
      case 'SUPPRESS FEATURE':
        api.suppress(_text(a, 0));
      case 'UNSUPPRESS FEATURE':
        api.unsuppress(_text(a, 0));
      case 'FREEZE FEATURE':
        api.freeze(_text(a, 0));
      case 'UNFREEZE FEATURE':
        api.unfreeze(_text(a, 0));
      case 'LIST FEATURES':
      case 'SHOW FEATURE TREE':
        result = api.features;
      case 'SHOW TIMELINE':
        result = api.engine.timeline;
      case 'SHOW DEPENDENCIES':
      case 'SHOW FEATURE GRAPH':
        result = api.engine.graphs.dependencies;
      case 'SHOW PARAMETERS':
        result = api.engine.parameters;
      case 'SHOW QUALITY':
        result = api.quality();
      case 'SHOW ADVISOR':
        result = api.recommendations();
      case 'SHOW HISTORY':
        result = api.engine.history.entries;
      case 'REBUILD MODEL':
        result = await api.rebuild();
      case 'ROLLBACK MODEL':
        api.engine.rollbackModel(_text(a, 0));
      case 'VALIDATE FEATURES':
        result = api.validate();
      case 'SHOW REBUILD QUEUE':
        result = api.engine.timeline.rebuildQueue;
      default:
        result = {
          'command': name,
          'geometryCreated': false,
          'status': 'platform-ready',
        };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, result),
      description: name,
    );
  }
}

List<FELCommand> createFeatureModelingFelCommands(FeatureModelingApi api) => [
  for (final n in const [
    'CREATE FEATURE',
    'DELETE FEATURE',
    'SUPPRESS FEATURE',
    'UNSUPPRESS FEATURE',
    'FREEZE FEATURE',
    'UNFREEZE FEATURE',
    'SHOW FEATURE TREE',
    'SHOW TIMELINE',
    'SHOW DEPENDENCIES',
    'SHOW PARAMETERS',
    'SHOW QUALITY',
    'SHOW ADVISOR',
    'SHOW HISTORY',
    'REBUILD MODEL',
    'ROLLBACK MODEL',
    'VALIDATE FEATURES',
    'LIST FEATURES',
    'SHOW FEATURE GRAPH',
    'SHOW REBUILD QUEUE',
    'SHOW EXECUTION ORDER',
    'SHOW IMPACT',
    'SHOW UPSTREAM',
    'SHOW DOWNSTREAM',
    'MARK DIRTY',
    'REBUILD PARTIAL',
    'REBUILD COMPLETE',
    'REBUILD INCREMENTAL',
    'SHOW FAILURES',
    'SHOW SUPPRESSED',
    'SHOW FROZEN',
    'SHOW REFERENCES',
    'SHOW PARENTS',
    'SHOW CHILDREN',
    'SHOW PARAMETER DIAGNOSTICS',
    'SHOW REBUILD STATUS',
  ])
    FeatureModelingFelCommand(n, api),
];
