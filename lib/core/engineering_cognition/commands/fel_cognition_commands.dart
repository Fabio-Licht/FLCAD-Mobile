import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../reverse_intelligence/brain/reverse_brain.dart';
import '../api/engineering_cognition_api.dart';
import '../orchestrator/cognition_orchestrator.dart';

class CognitionFELCommand implements FELCommand {
  CognitionFELCommand(this.name, this.action, this.api);
  @override
  final String name;
  final String action;
  final EngineeringCognitionApi api;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    CognitionResult result;
    final stored = context.variables['COGNITION_LAST']?.value;
    if (stored is CognitionResult) {
      result = stored;
    } else {
      final arei = context.variables['AREI_LAST']?.value;
      if (arei is! ReverseBrainResult) {
        throw StateError('ANALYZE MESH must be executed first');
      }
      result = api.analyze(arei.twin);
      context.variables['COGNITION_LAST'] = FELValue(
        FELType.dynamicType,
        result,
      );
    }
    final Object value;
    final FELType type;
    switch (action) {
      case 'features':
        value = result.snapshot.features;
        type = FELType.dynamicType;
      case 'part':
        value = result.snapshot.partClassifications;
        type = FELType.dynamicType;
      case 'function':
        value = result.snapshot.intents;
        type = FELType.dynamicType;
      case 'references':
        value = result.snapshot.references;
        type = FELType.dynamicType;
      case 'surfaces':
        value = result.snapshot.surfaces;
        type = FELType.dynamicType;
      case 'reconstruction':
        value = result.snapshot.reconstruction;
        type = FELType.dynamicType;
      case 'explainFeature':
        value = result.snapshot.features.map((f) => f.explanation).toList();
        type = FELType.dynamicType;
      case 'explainPart':
        value = result.snapshot.partClassifications
            .map(
              (p) => '${p.kind}: ${(p.probability * 100).toStringAsFixed(1)}%',
            )
            .join('\n');
        type = FELType.string;
      case 'analyze':
        value = result.snapshot;
        type = FELType.dynamicType;
      case 'graph':
        value = result.graph;
        type = FELType.dynamicType;
      default:
        throw UnsupportedError(action);
    }
    return FELCommandResult(
      value: FELValue(type, value),
      description: '$name completed',
    );
  }
}

List<FELCommand> createCognitionFELCommands() {
  final api = EngineeringCognitionApi();
  return [
    CognitionFELCommand('RECOGNIZE FEATURES', 'features', api),
    CognitionFELCommand('RECOGNIZE PART', 'part', api),
    CognitionFELCommand('RECOGNIZE FUNCTION', 'function', api),
    CognitionFELCommand('SUGGEST REFERENCES', 'references', api),
    CognitionFELCommand('SUGGEST SURFACES', 'surfaces', api),
    CognitionFELCommand('SUGGEST RECONSTRUCTION', 'reconstruction', api),
    CognitionFELCommand('EXPLAIN FEATURE', 'explainFeature', api),
    CognitionFELCommand('EXPLAIN PART', 'explainPart', api),
    CognitionFELCommand('ANALYZE ENGINEERING', 'analyze', api),
    CognitionFELCommand('BUILD FEATURE GRAPH', 'graph', api),
  ];
}
